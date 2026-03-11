// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../src/IrisAccount.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisApprovalQueue} from "../src/IrisApprovalQueue.sol";
import {SpendingCapEnforcer} from "../src/caveats/SpendingCapEnforcer.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";

/// @notice Simple target that stores the last call for verification.
contract CallReceiver {
    uint256 public lastValue;
    uint256 public callCount;
    address public lastCaller;

    function store(uint256 v) external payable {
        lastValue = v;
        lastCaller = msg.sender;
        callCount++;
    }

    receive() external payable {}
}

/// @notice Mock ERC-8004 reputation oracle.
contract MockReputationOracle {
    mapping(uint256 => uint256) public scores;

    function setScore(uint256 agentId, uint256 score) external {
        scores[agentId] = score;
    }

    function getReputationScore(uint256 agentId) external view returns (uint256) {
        return scores[agentId];
    }
}

contract IntegrationTest is Test {
    IrisAccountFactory factory;
    IrisDelegationManager delegationManager;
    IrisApprovalQueue approvalQueue;
    SpendingCapEnforcer spendingCap;
    ReputationGateEnforcer reputationGate;

    CallReceiver receiver;
    MockReputationOracle oracle;

    address delegatorOwner;
    uint256 delegatorOwnerKey;
    address agentDelegate;
    address stranger;

    IrisAccount account;

    function setUp() public {
        vm.warp(1_000_000);
        (delegatorOwner, delegatorOwnerKey) = makeAddrAndKey("delegatorOwner");
        agentDelegate = makeAddr("agent");
        stranger = makeAddr("stranger");

        factory = new IrisAccountFactory();
        delegationManager = new IrisDelegationManager();
        approvalQueue = new IrisApprovalQueue(1 days);
        spendingCap = new SpendingCapEnforcer();
        reputationGate = new ReputationGateEnforcer();

        receiver = new CallReceiver();
        oracle = new MockReputationOracle();

        address accountAddr = factory.createAccount(delegatorOwner, address(delegationManager), 0);
        account = IrisAccount(payable(accountAddr));
        vm.deal(address(account), 100 ether);
    }

    // -- Helpers --

    function helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return delegationManager.getDelegationHash(d);
    }

    function _getDelegationHash(Delegation memory d) internal view returns (bytes32) {
        return this.helperGetHash(d);
    }

    function _signDelegation(bytes32 dHash) internal view returns (bytes memory sig) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(delegatorOwnerKey, dHash);
        sig = abi.encodePacked(r, s, v);
    }

    function _buildDelegation(Caveat[] memory caveats, uint256 salt)
        internal view returns (Delegation memory d, bytes32 dHash)
    {
        d.delegator = address(account);
        d.delegate = agentDelegate;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = salt;
        d.signature = "";
        dHash = _getDelegationHash(d);
    }

    function _chain(Delegation memory d) internal pure returns (Delegation[] memory c) {
        c = new Delegation[](1);
        c[0] = d;
    }

    function _redeemAsAgent(Delegation[] memory chain, Action memory action) internal {
        vm.prank(agentDelegate);
        delegationManager.redeemDelegation(chain, action);
    }

    function _redeemSingleDelegation(Caveat[] memory caveats, uint256 salt, Action memory action) internal {
        (Delegation memory d, bytes32 dHash) = _buildDelegation(caveats, salt);
        d.signature = _signDelegation(dHash);
        _redeemAsAgent(_chain(d), action);
    }

    function _tryRedeem(Caveat[] memory caveats, uint256 salt, Action memory action) internal returns (bool ok) {
        (Delegation memory d, bytes32 dHash) = _buildDelegation(caveats, salt);
        d.signature = _signDelegation(dHash);
        vm.prank(agentDelegate);
        (ok,) = address(delegationManager).call(
            abi.encodeCall(delegationManager.redeemDelegation, (_chain(d), action))
        );
    }

    /// @dev Build a signed delegation and return it (for reuse across multiple redemptions).
    function _buildSignedDelegation(Caveat[] memory caveats, uint256 salt)
        internal view returns (Delegation memory d, bytes32 dHash)
    {
        (d, dHash) = _buildDelegation(caveats, salt);
        d.signature = _signDelegation(dHash);
    }

    // -- Full flow --

    function test_fullFlowNoCaveats() public {
        Caveat[] memory caveats = new Caveat[](0);
        Action memory action = Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (42))});
        _redeemSingleDelegation(caveats, 1, action);
        assertEq(receiver.lastValue(), 42);
        assertEq(receiver.callCount(), 1);
        assertEq(receiver.lastCaller(), address(account));
    }

    function test_fullFlowWithEthTransfer() public {
        Caveat[] memory caveats = new Caveat[](0);
        Action memory action = Action({target: address(receiver), value: 2 ether, callData: abi.encodeCall(CallReceiver.store, (7))});
        _redeemSingleDelegation(caveats, 2, action);
        assertEq(receiver.lastValue(), 7);
        assertEq(address(receiver).balance, 2 ether);
    }

    // -- Spending cap --

    function test_spendingCapUnderCapSucceeds() public {
        bytes memory terms = abi.encode(uint256(5 ether), uint256(1 days));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: terms});
        Action memory action = Action({target: address(receiver), value: 3 ether, callData: abi.encodeCall(CallReceiver.store, (100))});
        _redeemSingleDelegation(caveats, 10, action);
        assertEq(receiver.lastValue(), 100);
        assertEq(address(receiver).balance, 3 ether);
    }

    function test_spendingCapOverCapReverts() public {
        bytes memory terms = abi.encode(uint256(1 ether), uint256(1 days));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: terms});
        Action memory action = Action({target: address(receiver), value: 2 ether, callData: abi.encodeCall(CallReceiver.store, (999))});
        bool ok = _tryRedeem(caveats, 11, action);
        assertFalse(ok, "should revert when spending exceeds cap");
        assertEq(receiver.callCount(), 0);
    }

    function test_spendingCapCumulativeEnforcement() public {
        // The spending cap tracks spend per delegation hash. We must reuse the same
        // signed delegation for cumulative tracking to work across multiple redemptions.
        bytes memory terms = abi.encode(uint256(2 ether), uint256(1 days));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: terms});
        (Delegation memory d,) = _buildSignedDelegation(caveats, 20);

        // First redemption: 1.5 ether -- should succeed.
        _redeemAsAgent(_chain(d), Action({target: address(receiver), value: 1.5 ether, callData: abi.encodeCall(CallReceiver.store, (1))}));
        assertEq(receiver.callCount(), 1);

        // Second redemption: 1 ether -- cumulative 2.5 ether, should fail.
        vm.prank(agentDelegate);
        (bool ok,) = address(delegationManager).call(
            abi.encodeCall(delegationManager.redeemDelegation, (_chain(d), Action({target: address(receiver), value: 1 ether, callData: abi.encodeCall(CallReceiver.store, (2))})))
        );
        assertFalse(ok, "cumulative spend exceeds cap");
        assertEq(receiver.callCount(), 1);
    }

    function test_spendingCapResetsAfterPeriod() public {
        bytes memory terms = abi.encode(uint256(1 ether), uint256(1 days));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: terms});
        (Delegation memory d,) = _buildSignedDelegation(caveats, 22);

        // Spend the full 1 ether cap.
        _redeemAsAgent(_chain(d), Action({target: address(receiver), value: 1 ether, callData: abi.encodeCall(CallReceiver.store, (1))}));

        // Immediately trying to spend more should fail.
        vm.prank(agentDelegate);
        (bool ok,) = address(delegationManager).call(
            abi.encodeCall(delegationManager.redeemDelegation, (_chain(d), Action({target: address(receiver), value: 0.5 ether, callData: abi.encodeCall(CallReceiver.store, (2))})))
        );
        assertFalse(ok, "should fail within same period");

        // Warp to next day -- period resets.
        vm.warp(block.timestamp + 1 days);

        // Now spending should succeed again.
        _redeemAsAgent(_chain(d), Action({target: address(receiver), value: 0.5 ether, callData: abi.encodeCall(CallReceiver.store, (3))}));
        assertEq(receiver.lastValue(), 3);
    }

    // -- Reputation gate --

    function test_reputationGateAboveThresholdSucceeds() public {
        oracle.setScore(1, 80);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(reputationGate), terms: terms});
        Action memory action = Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (555))});
        _redeemSingleDelegation(caveats, 30, action);
        assertEq(receiver.lastValue(), 555);
    }

    function test_reputationGateBelowThresholdReverts() public {
        oracle.setScore(1, 30);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(reputationGate), terms: terms});
        Action memory action = Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (666))});
        bool ok = _tryRedeem(caveats, 31, action);
        assertFalse(ok, "should revert when reputation is below threshold");
        assertEq(receiver.callCount(), 0);
    }

    function test_reputationGateExactThresholdSucceeds() public {
        oracle.setScore(2, 60);
        bytes memory terms = abi.encode(address(oracle), uint256(2), uint256(60));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(reputationGate), terms: terms});
        Action memory action = Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (777))});
        _redeemSingleDelegation(caveats, 32, action);
        assertEq(receiver.lastValue(), 777);
    }

    function test_reputationDropBlocksSubsequentExecution() public {
        oracle.setScore(5, 80);
        bytes memory terms = abi.encode(address(oracle), uint256(5), uint256(50));
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(reputationGate), terms: terms});

        // First redemption succeeds.
        _redeemSingleDelegation(caveats, 80, Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (1))}));
        assertEq(receiver.callCount(), 1);

        // Reputation drops below threshold.
        oracle.setScore(5, 20);

        // Second redemption with different salt fails.
        bool ok = _tryRedeem(caveats, 81, Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (2))}));
        assertFalse(ok, "lowered reputation should block execution");
        assertEq(receiver.callCount(), 1);
    }

    // -- Combined caveats --

    function test_combinedCaveatsAllPass() public {
        oracle.setScore(1, 90);
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(10 ether), uint256(1 days))});
        caveats[1] = Caveat({enforcer: address(reputationGate), terms: abi.encode(address(oracle), uint256(1), uint256(50))});
        Action memory action = Action({target: address(receiver), value: 1 ether, callData: abi.encodeCall(CallReceiver.store, (888))});
        _redeemSingleDelegation(caveats, 40, action);
        assertEq(receiver.lastValue(), 888);
        assertEq(address(receiver).balance, 1 ether);
    }

    function test_combinedCaveatsReputationFailsBlocksExecution() public {
        oracle.setScore(1, 10);
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(10 ether), uint256(1 days))});
        caveats[1] = Caveat({enforcer: address(reputationGate), terms: abi.encode(address(oracle), uint256(1), uint256(50))});
        Action memory action = Action({target: address(receiver), value: 1 ether, callData: abi.encodeCall(CallReceiver.store, (999))});
        bool ok = _tryRedeem(caveats, 41, action);
        assertFalse(ok, "reputation failure should block execution");
        assertEq(receiver.callCount(), 0);
    }

    // -- Delegation revocation --

    function test_delegationRevocationBlocksRedemption() public {
        Caveat[] memory caveats = new Caveat[](0);
        (Delegation memory d, bytes32 dHash) = _buildSignedDelegation(caveats, 50);
        vm.prank(delegatorOwner);
        delegationManager.revokeDelegation(dHash);
        vm.prank(agentDelegate);
        vm.expectRevert(abi.encodeWithSelector(IrisDelegationManager.DelegationIsRevoked.selector, dHash));
        delegationManager.redeemDelegation(
            _chain(d),
            Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (0))})
        );
    }

    function test_accountLevelRevocationState() public {
        Caveat[] memory caveats = new Caveat[](0);
        (, bytes32 dHash) = _buildDelegation(caveats, 51);
        vm.prank(delegatorOwner);
        account.revokeDelegation(dHash);
        assertFalse(account.isDelegationValid(dHash));
        assertFalse(delegationManager.revokedDelegations(dHash));
    }

    // -- Unauthorized manager --

    function test_unauthorizedManagerReverts() public {
        IrisDelegationManager rogueManager = new IrisDelegationManager();
        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentDelegate;
        d.authority = address(0);
        d.caveats = new Caveat[](0);
        d.salt = 60;
        bytes32 dHash = this.helperGetHashFromManager(rogueManager, d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(delegatorOwnerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);
        vm.prank(agentDelegate);
        vm.expectRevert(IrisDelegationManager.ManagerNotAuthorized.selector);
        rogueManager.redeemDelegation(
            _chain(d),
            Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (0))})
        );
    }

    function helperGetHashFromManager(IrisDelegationManager mgr, Delegation calldata d)
        external view returns (bytes32)
    {
        return mgr.getDelegationHash(d);
    }

    // -- Non-delegate --

    function test_nonDelegateCannotRedeem() public {
        Caveat[] memory caveats = new Caveat[](0);
        (Delegation memory d,) = _buildSignedDelegation(caveats, 70);
        vm.prank(stranger);
        vm.expectRevert(IrisDelegationManager.InvalidDelegationChain.selector);
        delegationManager.redeemDelegation(
            _chain(d),
            Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (0))})
        );
    }

    // -- Empty chain --

    function test_emptyDelegationChainReverts() public {
        Delegation[] memory emptyChain = new Delegation[](0);
        vm.prank(agentDelegate);
        vm.expectRevert(IrisDelegationManager.EmptyDelegationChain.selector);
        delegationManager.redeemDelegation(
            emptyChain,
            Action({target: address(receiver), value: 0, callData: abi.encodeCall(CallReceiver.store, (0))})
        );
    }

    // -- Approval queue --

    function test_approvalQueueFullFlow() public {
        vm.prank(agentDelegate);
        bytes32 requestId = approvalQueue.submitRequest(
            address(receiver), abi.encodeCall(CallReceiver.store, (42)), 0, keccak256("delegation"), delegatorOwner
        );
        bytes32[] memory pending = approvalQueue.getPendingRequests(delegatorOwner);
        assertEq(pending.length, 1);
        assertEq(pending[0], requestId);
        vm.prank(delegatorOwner);
        approvalQueue.approveRequest(requestId);
        IrisApprovalQueue.ApprovalRequest memory req = approvalQueue.getRequest(requestId);
        assertTrue(req.approved);
        assertFalse(req.rejected);
    }

    // -- Owner direct execution --

    function test_ownerDirectExecutionBypassesDelegation() public {
        vm.prank(delegatorOwner);
        account.execute(address(receiver), 0, abi.encodeCall(CallReceiver.store, (12345)));
        assertEq(receiver.lastValue(), 12345);
        assertEq(receiver.lastCaller(), address(account));
    }

    // -- Factory prediction --

    function test_factoryPredictionMatchesDeployedAccount() public view {
        address predicted = factory.getAddress(delegatorOwner, address(delegationManager), 0);
        assertEq(predicted, address(account));
    }
}
