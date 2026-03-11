// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockUniswapRouter} from "../../src/mocks/MockUniswapRouter.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @title FullDelegationFlow Integration Test
/// @notice Complete happy path: deploy → register → create account → fund → delegate → execute → block → upgrade → revoke
contract FullDelegationFlowTest is Test {
    IrisAccountFactory factory;
    IrisDelegationManager delegationManager;
    IrisAgentRegistry agentRegistry;
    IrisReputationOracle reputationOracle;
    SpendingCapEnforcer spendingCap;
    ContractWhitelistEnforcer contractWhitelist;
    TimeWindowEnforcer timeWindow;
    ReputationGateEnforcer reputationGate;
    MockERC20 mockUSDC;
    MockUniswapRouter mockRouter;

    address owner;
    uint256 ownerKey;
    address agent;
    uint256 agentKey;
    IrisAccount ownerAccount;
    uint256 agentId;

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        (agent, agentKey) = makeAddrAndKey("agent");

        delegationManager = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        agentRegistry = new IrisAgentRegistry();
        reputationOracle = new IrisReputationOracle(address(agentRegistry), address(this));
        spendingCap = new SpendingCapEnforcer();
        contractWhitelist = new ContractWhitelistEnforcer();
        timeWindow = new TimeWindowEnforcer();
        reputationGate = new ReputationGateEnforcer();
        mockUSDC = new MockERC20("Mock USDC", "USDC");
        mockRouter = new MockUniswapRouter();
    }

    function helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return delegationManager.getDelegationHash(d);
    }

    function helperRedeem(Delegation[] calldata chain, Action calldata action) external {
        delegationManager.redeemDelegation(chain, action);
    }

    function _signDelegation(Delegation memory d, uint256 pk) internal view returns (Delegation memory) {
        bytes32 hash = this.helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, hash);
        d.signature = abi.encodePacked(r, s, v);
        return d;
    }

    /// @notice 10-step full delegation lifecycle
    function test_fullDelegationLifecycle() public {
        // Step 1: Deploy (done in setUp)

        // Step 2: Register agent
        vm.prank(agent);
        agentId = agentRegistry.registerAgent("ipfs://test-agent");
        assertTrue(agentRegistry.isRegistered(agentId));

        // Step 3: Owner creates IrisAccount
        address accountAddr = factory.createAccount(owner, address(delegationManager), 0);
        ownerAccount = IrisAccount(payable(accountAddr));
        assertEq(ownerAccount.owner(), owner);

        // Step 4: Fund account with MockERC20 and ETH
        mockUSDC.mint(accountAddr, 10_000 ether);
        vm.deal(accountAddr, 100 ether);
        assertEq(mockUSDC.balanceOf(accountAddr), 10_000 ether);

        // Step 5: Grant Tier 1 delegation (spending cap: 1 ETH/day, whitelist: mockRouter, time: 7 days, rep: 40)
        address[] memory allowed = new address[](1);
        allowed[0] = address(mockRouter);

        Caveat[] memory caveats = new Caveat[](4);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(1 ether), uint256(86400))});
        caveats[1] = Caveat({enforcer: address(contractWhitelist), terms: abi.encode(allowed)});
        caveats[2] = Caveat({enforcer: address(timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 7 days)});
        caveats[3] = Caveat({enforcer: address(reputationGate), terms: abi.encode(address(reputationOracle), agentId, uint256(40))});

        Delegation memory delegation = Delegation({
            delegator: accountAddr,
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = delegation;

        // Step 6: Agent executes swap within cap (0.5 ETH value)
        // First approve mockRouter from ownerAccount
        vm.prank(owner);
        ownerAccount.execute(
            address(mockUSDC),
            0,
            abi.encodeCall(MockERC20.approve, (address(mockRouter), type(uint256).max))
        );

        // Agent swaps via delegation — target is mockRouter, sending 0.5 ETH
        Action memory swapAction = Action({
            target: address(mockRouter),
            value: 0.5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 100 ether))
        });

        vm.prank(agent);
        delegationManager.redeemDelegation(chain, swapAction);

        // Step 7: Agent tries swap over cap (2 ETH value → total 2.5 > 1 cap)
        Action memory bigAction = Action({
            target: address(mockRouter),
            value: 2 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 50 ether))
        });

        vm.prank(agent);
        vm.expectRevert(); // SpendingCapExceeded
        delegationManager.redeemDelegation(chain, bigAction);

        // Step 8: Owner upgrades to Tier 2 (higher daily cap: 10 ETH)
        Caveat[] memory tier2Caveats = new Caveat[](4);
        tier2Caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(10 ether), uint256(86400))});
        tier2Caveats[1] = Caveat({enforcer: address(contractWhitelist), terms: abi.encode(allowed)});
        tier2Caveats[2] = Caveat({enforcer: address(timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 30 days)});
        tier2Caveats[3] = Caveat({enforcer: address(reputationGate), terms: abi.encode(address(reputationOracle), agentId, uint256(40))});

        Delegation memory tier2Del = Delegation({
            delegator: accountAddr,
            delegate: agent,
            authority: address(0),
            caveats: tier2Caveats,
            salt: 2,
            signature: ""
        });
        tier2Del = _signDelegation(tier2Del, ownerKey);
        Delegation[] memory chain2 = new Delegation[](1);
        chain2[0] = tier2Del;

        // Step 9: Agent executes larger swap (5 ETH) → succeeds with Tier 2
        Action memory largeAction = Action({
            target: address(mockRouter),
            value: 5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 200 ether))
        });

        vm.prank(agent);
        delegationManager.redeemDelegation(chain2, largeAction);

        // Step 10: Owner revokes → agent blocked
        bytes32 hash = this.helperGetHash(tier2Del);
        vm.prank(owner);
        delegationManager.revokeDelegation(hash);

        vm.prank(agent);
        vm.expectRevert(); // DelegationIsRevoked
        delegationManager.redeemDelegation(chain2, largeAction);
    }
}
