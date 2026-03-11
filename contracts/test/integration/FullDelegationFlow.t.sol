// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {MockERC20} from "../../src/mocks/MockERC20.sol";
import {MockUniswapRouter} from "../../src/mocks/MockUniswapRouter.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @title FullDelegationFlow Integration Test
/// @notice Complete happy path: deploy → register → create account → fund → delegate → execute → block → upgrade → revoke.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract FullDelegationFlowTest is IrisTestBase {
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

        _deployIris();
        mockUSDC = new MockERC20("Mock USDC", "USDC");
        mockRouter = new MockUniswapRouter();
    }

    /// @notice 10-step full delegation lifecycle
    function test_fullDelegationLifecycle() public {
        // Step 2: Register agent
        agentId = _registerAgent(agent, "ipfs://test-agent");
        assertTrue(d.agentRegistry.isRegistered(agentId));

        // Step 3: Owner creates IrisAccount
        ownerAccount = _createFundedAccount(owner, 100 ether);
        assertEq(ownerAccount.owner(), owner);
        address accountAddr = address(ownerAccount);

        // Step 4: Fund account with MockERC20
        mockUSDC.mint(accountAddr, 10_000 ether);
        assertEq(mockUSDC.balanceOf(accountAddr), 10_000 ether);

        // Step 5: Grant Tier 1 delegation
        address[] memory allowed = new address[](1);
        allowed[0] = address(mockRouter);

        Caveat[] memory caveats = new Caveat[](4);
        caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(1 ether), uint256(86400))});
        caveats[1] = Caveat({enforcer: address(d.contractWhitelist), terms: abi.encode(allowed)});
        caveats[2] = Caveat({enforcer: address(d.timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 7 days)});
        caveats[3] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(40))});

        Delegation memory delegation = Delegation({
            delegator: accountAddr,
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });
        delegation = _signDelegation(delegation, ownerKey);

        // Step 6: Agent executes swap within cap
        vm.prank(owner);
        ownerAccount.execute(
            address(mockUSDC), 0,
            abi.encodeCall(MockERC20.approve, (address(mockRouter), type(uint256).max))
        );

        _redeemAs(agent, delegation, Action({
            target: address(mockRouter),
            value: 0.5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 100 ether))
        }));

        // Step 7: Agent tries swap over cap
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = delegation;
        vm.prank(agent);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chain, Action({
            target: address(mockRouter),
            value: 2 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 50 ether))
        }));

        // Step 8: Owner upgrades to Tier 2
        Caveat[] memory tier2Caveats = new Caveat[](4);
        tier2Caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(10 ether), uint256(86400))});
        tier2Caveats[1] = Caveat({enforcer: address(d.contractWhitelist), terms: abi.encode(allowed)});
        tier2Caveats[2] = Caveat({enforcer: address(d.timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 30 days)});
        tier2Caveats[3] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(40))});

        Delegation memory tier2Del = Delegation({
            delegator: accountAddr, delegate: agent, authority: address(0),
            caveats: tier2Caveats, salt: 2, signature: ""
        });
        tier2Del = _signDelegation(tier2Del, ownerKey);

        // Step 9: Agent executes larger swap
        _redeemAs(agent, tier2Del, Action({
            target: address(mockRouter),
            value: 5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 200 ether))
        }));

        // Step 10: Owner revokes → agent blocked
        vm.prank(owner);
        d.delegationManager.revokeDelegation(tier2Del);

        Delegation[] memory chain2 = new Delegation[](1);
        chain2[0] = tier2Del;
        vm.prank(agent);
        vm.expectRevert();
        d.delegationManager.redeemDelegation(chain2, Action({
            target: address(mockRouter),
            value: 5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swap, (address(mockUSDC), address(mockUSDC), 200 ether))
        }));
    }
}
