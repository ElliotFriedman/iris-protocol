// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisApprovalQueue} from "../../src/IrisApprovalQueue.sol";
import {TierOne} from "../../src/presets/TierOne.sol";
import {TierTwo} from "../../src/presets/TierTwo.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Mock Uniswap router for demo purposes.
contract MockUniswapRouter {
    uint256 public swapCount;
    uint256 public totalIn;

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts)
    {
        swapCount++;
        totalIn += msg.value;
        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = amountOutMin;
    }

    receive() external payable {}
}

/// @title DemoFlowTest
/// @notice Recreates the 9-step demo flow described in the Iris Protocol spec.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract DemoFlowTest is IrisTestBase {
    // Actors
    address user;
    uint256 userKey;
    address agentOp;

    // Contracts
    IrisAccount wallet;
    MockUniswapRouter uniswap;

    // Agent identity
    uint256 agentId;

    function setUp() public {
        vm.warp(1_000_000);
        _deployIris();
        (user, userKey) = makeAddrAndKey("user");
        agentOp = makeAddr("agentOperator");
        uniswap = new MockUniswapRouter();
    }

    function _signDel(Delegation memory del) internal view returns (Delegation memory) {
        return _signDelegation(del, userKey);
    }

    // =========================================================================
    // THE 9-STEP DEMO FLOW
    // =========================================================================

    function test_fullDemoFlow() public {
        // STEP 1: Agent registers
        agentId = _registerAgent(agentOp, "ipfs://QmAgentCard4521");
        assertTrue(d.agentRegistry.isRegistered(agentId));
        assertEq(d.agentRegistry.ownerOf(agentId), agentOp);
        assertEq(d.reputationOracle.getReputationScore(agentId), 50);

        // STEP 2: User creates an Iris wallet
        address predictedAddr = d.factory.getAddress(user, address(d.delegationManager), 0);
        wallet = _createFundedAccount(user, 500 ether);
        assertEq(address(wallet), predictedAddr);
        assertEq(wallet.owner(), user);

        // STEP 3: Build reputation
        for (uint256 i = 0; i < 5; i++) {
            d.reputationOracle.submitFeedback(agentId, true);
        }
        assertEq(d.reputationOracle.getReputationScore(agentId), 60);

        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(uniswap);

        Caveat[] memory tier1Caveats = TierOne.configureTierOne(
            address(d.spendingCap), address(d.contractWhitelist),
            address(d.timeWindow), address(d.reputationGate),
            address(d.reputationOracle), agentId,
            100 ether, allowedContracts, block.timestamp + 7 days, 40
        );

        // STEP 4: User approves
        Delegation memory delegation;
        delegation.delegator = address(wallet);
        delegation.delegate = agentOp;
        delegation.authority = address(0);
        delegation.caveats = tier1Caveats;
        delegation.salt = 1;
        delegation = _signDel(delegation);

        // STEP 5: Agent executes a $50 Uniswap swap
        address[] memory path = new address[](2);
        path[0] = makeAddr("WETH");
        path[1] = makeAddr("USDC");

        _redeemAs(agentOp, delegation, Action({
            target: address(uniswap),
            value: 50 ether,
            callData: abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (45 ether, path, address(wallet), block.timestamp + 1 hours))
        }));
        assertEq(uniswap.swapCount(), 1);
        assertEq(uniswap.totalIn(), 50 ether);

        // STEP 6: Agent attempts a $200 swap — blocked
        Delegation memory delegation2;
        delegation2.delegator = address(wallet);
        delegation2.delegate = agentOp;
        delegation2.authority = address(0);
        delegation2.caveats = tier1Caveats;
        delegation2.salt = 2;
        delegation2 = _signDel(delegation2);

        Action memory bigSwapAction = Action({
            target: address(uniswap),
            value: 200 ether,
            callData: abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (180 ether, path, address(wallet), block.timestamp + 1 hours))
        });

        bool ok = _tryRedeemAs(agentOp, delegation2, bigSwapAction);
        assertFalse(ok, "Step 6: $200 swap should be blocked by spending cap");

        // Agent submits to approval queue
        bytes32 delegationHash = this._helperGetHash(delegation2);
        vm.prank(agentOp);
        bytes32 requestId = d.approvalQueue.submitRequest(
            address(uniswap), bigSwapAction.callData, 200 ether, delegationHash, user
        );
        assertEq(d.approvalQueue.getPendingRequests(user).length, 1);

        // STEP 7: User bumps agent to Tier 2
        vm.prank(user);
        d.approvalQueue.approveRequest(requestId);
        assertTrue(d.approvalQueue.getRequest(requestId).approved);

        Caveat[] memory tier2Caveats = new Caveat[](2);
        tier2Caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(500 ether), uint256(1 days))});
        tier2Caveats[1] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(50))});

        Delegation memory tier2Delegation;
        tier2Delegation.delegator = address(wallet);
        tier2Delegation.delegate = agentOp;
        tier2Delegation.authority = address(0);
        tier2Delegation.caveats = tier2Caveats;
        tier2Delegation.salt = 3;
        tier2Delegation = _signDel(tier2Delegation);

        _redeemAs(agentOp, tier2Delegation, bigSwapAction);
        assertEq(uniswap.swapCount(), 2);

        // STEP 8: Reputation drop blocks
        d.reputationOracle.submitFeedback(agentId, false); // 60 -> 55
        d.reputationOracle.submitFeedback(agentId, false); // 55 -> 50
        d.reputationOracle.submitFeedback(agentId, false); // 50 -> 45
        assertEq(d.reputationOracle.getReputationScore(agentId), 45);

        Delegation memory tier2Delegation2;
        tier2Delegation2.delegator = address(wallet);
        tier2Delegation2.delegate = agentOp;
        tier2Delegation2.authority = address(0);
        tier2Delegation2.caveats = tier2Caveats;
        tier2Delegation2.salt = 4;
        tier2Delegation2 = _signDel(tier2Delegation2);

        ok = _tryRedeemAs(agentOp, tier2Delegation2, Action({
            target: address(uniswap),
            value: 10 ether,
            callData: abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (9 ether, path, address(wallet), block.timestamp + 1 hours))
        }));
        assertFalse(ok, "Step 8: Reputation below threshold blocks execution");

        // STEP 9: User instantly revokes
        bytes32 tier1Hash = this._helperGetHash(delegation);
        bytes32 tier2Hash = this._helperGetHash(tier2Delegation);
        vm.startPrank(user);
        wallet.revokeDelegation(tier1Hash);
        wallet.revokeDelegation(tier2Hash);
        vm.stopPrank();

        assertFalse(wallet.isDelegationValid(tier1Hash));
        assertFalse(wallet.isDelegationValid(tier2Hash));

        // Even if reputation recovers, revoked delegations stay revoked — but new ones work
        d.reputationOracle.submitFeedback(agentId, true);
        d.reputationOracle.submitFeedback(agentId, true);
        d.reputationOracle.submitFeedback(agentId, true);

        Delegation memory tier2Delegation3;
        tier2Delegation3.delegator = address(wallet);
        tier2Delegation3.delegate = agentOp;
        tier2Delegation3.authority = address(0);
        tier2Delegation3.caveats = tier2Caveats;
        tier2Delegation3.salt = 5;
        tier2Delegation3 = _signDel(tier2Delegation3);

        _redeemAs(agentOp, tier2Delegation3, Action({
            target: address(uniswap),
            value: 5 ether,
            callData: abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (4 ether, path, address(wallet), block.timestamp + 1 hours))
        }));
        assertEq(uniswap.swapCount(), 3);
    }

    function test_agentLifecycle_registerToTierUpgrade() public {
        address newAgentOp = makeAddr("newAgent");
        uint256 newAgentId = _registerAgent(newAgentOp, "ipfs://new-agent");
        assertEq(d.reputationOracle.getReputationScore(newAgentId), 50);

        wallet = _createFundedAccount(user, 100 ether, 99);
        address payable recipient = payable(makeAddr("recipient"));

        // Tier 1 (min rep 40)
        Caveat[] memory tier1Caveats = new Caveat[](1);
        tier1Caveats[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), newAgentId, uint256(40))});

        Delegation memory d1;
        d1.delegator = address(wallet);
        d1.delegate = newAgentOp;
        d1.authority = address(0);
        d1.caveats = tier1Caveats;
        d1.salt = 1;
        d1 = _signDelegation(d1, userKey);

        _redeemAs(newAgentOp, d1, Action({target: recipient, value: 1 ether, callData: ""}));
        assertEq(recipient.balance, 1 ether);

        // Tier 2 (min rep 75) — blocked
        Caveat[] memory tier2Caveats = new Caveat[](1);
        tier2Caveats[0] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), newAgentId, uint256(75))});

        Delegation memory d2;
        d2.delegator = address(wallet);
        d2.delegate = newAgentOp;
        d2.authority = address(0);
        d2.caveats = tier2Caveats;
        d2.salt = 2;
        d2 = _signDelegation(d2, userKey);

        bool ok = _tryRedeemAs(newAgentOp, d2, Action({target: recipient, value: 1 ether, callData: ""}));
        assertFalse(ok, "Agent cannot access Tier 2 at reputation 50");

        // Build reputation: 50 -> 76
        for (uint256 i = 0; i < 13; i++) {
            d.reputationOracle.submitFeedback(newAgentId, true);
        }
        assertEq(d.reputationOracle.getReputationScore(newAgentId), 76);

        Delegation memory d3;
        d3.delegator = address(wallet);
        d3.delegate = newAgentOp;
        d3.authority = address(0);
        d3.caveats = tier2Caveats;
        d3.salt = 3;
        d3 = _signDelegation(d3, userKey);

        _redeemAs(newAgentOp, d3, Action({target: recipient, value: 1 ether, callData: ""}));
        assertEq(recipient.balance, 2 ether);
    }

    function test_approvalQueue_expiry() public {
        agentId = _registerAgent(agentOp, "ipfs://agent");
        wallet = _createFundedAccount(user, 0, 50);

        vm.prank(agentOp);
        bytes32 requestId = d.approvalQueue.submitRequest(
            address(uniswap),
            abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (0, new address[](0), address(0), 0)),
            100 ether, keccak256("delegation"), user
        );

        assertFalse(d.approvalQueue.isExpired(requestId));
        vm.warp(block.timestamp + 1 days + 1);
        assertTrue(d.approvalQueue.isExpired(requestId));

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestExpired.selector, requestId));
        d.approvalQueue.approveRequest(requestId);
    }
}
