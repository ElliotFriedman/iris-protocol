// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisApprovalQueue} from "../src/IrisApprovalQueue.sol";

contract IrisApprovalQueueTest is Test {
    IrisApprovalQueue queue;

    address agent = makeAddr("agent");
    address delegator = makeAddr("delegator");
    address stranger = makeAddr("stranger");
    address target = makeAddr("target");

    uint256 constant EXPIRY = 1 days;

    function setUp() public {
        queue = new IrisApprovalQueue(EXPIRY);
        vm.warp(1_000_000); // deterministic start time
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    function _submit() internal returns (bytes32 requestId) {
        vm.prank(agent);
        requestId = queue.submitRequest(target, hex"aabbccdd", 1 ether, keccak256("delegation"), delegator);
    }

    // -----------------------------------------------------------------------
    // submitRequest
    // -----------------------------------------------------------------------

    function test_submitRequestStoresCorrectData() public {
        bytes32 requestId = _submit();

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertEq(req.agent, agent);
        assertEq(req.target, target);
        assertEq(req.value, 1 ether);
        assertEq(req.delegationHash, keccak256("delegation"));
        assertEq(req.submittedAt, block.timestamp);
        assertFalse(req.approved);
        assertFalse(req.rejected);
        assertFalse(req.executed);
    }

    function test_submitRequestEmitsEvent() public {
        vm.prank(agent);
        vm.expectEmit(true, true, true, true);
        emit IrisApprovalQueue.ApprovalRequested(
            // We can't predict the exact requestId here, so use the indexed topics
            // Actually, we need to calculate it. Let's just check the event is emitted.
            keccak256(abi.encode(agent, target, uint256(1 ether), keccak256("delegation"), block.timestamp, uint256(0))),
            agent,
            delegator,
            target,
            1 ether
        );
        queue.submitRequest(target, hex"aabbccdd", 1 ether, keccak256("delegation"), delegator);
    }

    function test_submitMultipleRequestsUniqueIds() public {
        vm.startPrank(agent);
        bytes32 id1 = queue.submitRequest(target, hex"aa", 1 ether, keccak256("d1"), delegator);
        bytes32 id2 = queue.submitRequest(target, hex"bb", 2 ether, keccak256("d2"), delegator);
        vm.stopPrank();

        assertTrue(id1 != id2, "request IDs should be unique");
    }

    function test_submitRequestAddsToPendingRequests() public {
        bytes32 id1 = _submit();

        vm.prank(agent);
        bytes32 id2 = queue.submitRequest(target, hex"bb", 0, keccak256("d2"), delegator);

        bytes32[] memory pending = queue.getPendingRequests(delegator);
        assertEq(pending.length, 2);
        assertEq(pending[0], id1);
        assertEq(pending[1], id2);
    }

    // -----------------------------------------------------------------------
    // approveRequest
    // -----------------------------------------------------------------------

    function test_approveRequestByDelegator() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.approveRequest(requestId);

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertTrue(req.approved);
        assertFalse(req.rejected);
    }

    function test_approveRequestEmitsEvent() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        vm.expectEmit(true, true, false, false);
        emit IrisApprovalQueue.ApprovalGranted(requestId, delegator);
        queue.approveRequest(requestId);
    }

    function test_approveRequestRevertsForStranger() public {
        bytes32 requestId = _submit();

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.NotDelegator.selector, requestId, stranger));
        queue.approveRequest(requestId);
    }

    function test_approveAlreadyApprovedReverts() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.approveRequest(requestId);

        vm.prank(delegator);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestAlreadyResolved.selector, requestId));
        queue.approveRequest(requestId);
    }

    // -----------------------------------------------------------------------
    // rejectRequest
    // -----------------------------------------------------------------------

    function test_rejectRequestByDelegator() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.rejectRequest(requestId);

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertFalse(req.approved);
        assertTrue(req.rejected);
    }

    function test_rejectRequestEmitsEvent() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        vm.expectEmit(true, true, false, false);
        emit IrisApprovalQueue.ApprovalRejected(requestId, delegator);
        queue.rejectRequest(requestId);
    }

    function test_rejectRequestRevertsForStranger() public {
        bytes32 requestId = _submit();

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.NotDelegator.selector, requestId, stranger));
        queue.rejectRequest(requestId);
    }

    function test_rejectAlreadyRejectedReverts() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.rejectRequest(requestId);

        vm.prank(delegator);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestAlreadyResolved.selector, requestId));
        queue.rejectRequest(requestId);
    }

    function test_approveAlreadyRejectedReverts() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.rejectRequest(requestId);

        vm.prank(delegator);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestAlreadyResolved.selector, requestId));
        queue.approveRequest(requestId);
    }

    // -----------------------------------------------------------------------
    // Expiry logic
    // -----------------------------------------------------------------------

    function test_isExpiredReturnsFalseBeforeExpiry() public {
        bytes32 requestId = _submit();
        assertFalse(queue.isExpired(requestId));
    }

    function test_isExpiredReturnsTrueAfterExpiry() public {
        bytes32 requestId = _submit();
        vm.warp(block.timestamp + EXPIRY + 1);
        assertTrue(queue.isExpired(requestId));
    }

    function test_approveExpiredRequestReverts() public {
        bytes32 requestId = _submit();
        vm.warp(block.timestamp + EXPIRY + 1);

        vm.prank(delegator);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestExpired.selector, requestId));
        queue.approveRequest(requestId);
    }

    function test_rejectExpiredRequestReverts() public {
        bytes32 requestId = _submit();
        vm.warp(block.timestamp + EXPIRY + 1);

        vm.prank(delegator);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestExpired.selector, requestId));
        queue.rejectRequest(requestId);
    }

    function test_isExpiredRevertsForNonexistentRequest() public {
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.RequestNotFound.selector, bytes32(uint256(0xdead)))
        );
        queue.isExpired(bytes32(uint256(0xdead)));
    }

    // -----------------------------------------------------------------------
    // getPendingRequests
    // -----------------------------------------------------------------------

    function test_getPendingRequestsEmptyByDefault() public view {
        bytes32[] memory pending = queue.getPendingRequests(delegator);
        assertEq(pending.length, 0);
    }

    function test_getPendingRequestsReturnsAllRequests() public {
        bytes32 id1 = _submit();

        vm.prank(agent);
        bytes32 id2 = queue.submitRequest(target, hex"bb", 0, keccak256("d2"), delegator);

        vm.prank(agent);
        bytes32 id3 = queue.submitRequest(target, hex"cc", 0, keccak256("d3"), delegator);

        bytes32[] memory pending = queue.getPendingRequests(delegator);
        assertEq(pending.length, 3);
        assertEq(pending[0], id1);
        assertEq(pending[1], id2);
        assertEq(pending[2], id3);
    }

    // -----------------------------------------------------------------------
    // getRequest
    // -----------------------------------------------------------------------

    function test_getRequestRevertsForNonexistent() public {
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.RequestNotFound.selector, bytes32(uint256(0xbeef)))
        );
        queue.getRequest(bytes32(uint256(0xbeef)));
    }

    function test_expiryDurationIsSetCorrectly() public view {
        assertEq(queue.expiryDuration(), EXPIRY);
    }
}
