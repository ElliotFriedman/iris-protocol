// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisApprovalQueue} from "../../src/IrisApprovalQueue.sol";

contract IrisApprovalQueueTest is Test {
    IrisApprovalQueue queue;
    address agent;
    address delegator;
    address stranger;
    uint256 constant EXPIRY = 86400; // 24 hours

    event ApprovalRequested(
        bytes32 indexed requestId, address indexed agent, address indexed delegator, address target, uint256 value
    );
    event ApprovalGranted(bytes32 indexed requestId, address indexed delegator);
    event ApprovalRejected(bytes32 indexed requestId, address indexed delegator);

    function setUp() public {
        queue = new IrisApprovalQueue(EXPIRY);
        agent = makeAddr("agent");
        delegator = makeAddr("delegator");
        stranger = makeAddr("stranger");
    }

    function _submit() internal returns (bytes32 requestId) {
        vm.prank(agent);
        requestId = queue.submitRequest(makeAddr("target"), "", 1 ether, keccak256("delHash"), delegator);
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    function test_constructor_setsExpiry() public view {
        assertEq(queue.expiryDuration(), EXPIRY);
    }

    // -----------------------------------------------------------------------
    // submitRequest
    // -----------------------------------------------------------------------

    function test_submitRequest_createsRequest() public {
        bytes32 requestId = _submit();

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertEq(req.agent, agent);
        assertEq(req.value, 1 ether);
        assertFalse(req.approved);
        assertFalse(req.rejected);
        assertFalse(req.executed);
    }

    function test_submitRequest_addsToPendingList() public {
        bytes32 requestId = _submit();

        bytes32[] memory pending = queue.getPendingRequests(delegator);
        assertEq(pending.length, 1);
        assertEq(pending[0], requestId);
    }

    function test_submitRequest_emitsEvent() public {
        address target = makeAddr("target");
        vm.prank(agent);
        vm.expectEmit(false, true, true, true);
        emit ApprovalRequested(bytes32(0), agent, delegator, target, 1 ether);
        queue.submitRequest(target, "", 1 ether, keccak256("delHash"), delegator);
    }

    // -----------------------------------------------------------------------
    // approveRequest
    // -----------------------------------------------------------------------

    function test_approveRequest_setsApproved() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        vm.expectEmit(true, true, false, false);
        emit ApprovalGranted(requestId, delegator);
        queue.approveRequest(requestId);

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertTrue(req.approved);
    }

    function test_approveRequest_revertsForStranger() public {
        bytes32 requestId = _submit();

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.NotDelegator.selector, requestId, stranger)
        );
        queue.approveRequest(requestId);
    }

    function test_approveRequest_revertsIfAlreadyApproved() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        queue.approveRequest(requestId);

        vm.prank(delegator);
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.RequestAlreadyResolved.selector, requestId)
        );
        queue.approveRequest(requestId);
    }

    function test_approveRequest_revertsIfExpired() public {
        bytes32 requestId = _submit();
        vm.warp(block.timestamp + EXPIRY + 1);

        vm.prank(delegator);
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.RequestExpired.selector, requestId)
        );
        queue.approveRequest(requestId);
    }

    // -----------------------------------------------------------------------
    // rejectRequest
    // -----------------------------------------------------------------------

    function test_rejectRequest_setsRejected() public {
        bytes32 requestId = _submit();

        vm.prank(delegator);
        vm.expectEmit(true, true, false, false);
        emit ApprovalRejected(requestId, delegator);
        queue.rejectRequest(requestId);

        IrisApprovalQueue.ApprovalRequest memory req = queue.getRequest(requestId);
        assertTrue(req.rejected);
    }

    function test_rejectRequest_revertsForStranger() public {
        bytes32 requestId = _submit();

        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisApprovalQueue.NotDelegator.selector, requestId, stranger)
        );
        queue.rejectRequest(requestId);
    }

    // -----------------------------------------------------------------------
    // Views
    // -----------------------------------------------------------------------

    function test_getRequest_revertsForNonExistent() public {
        bytes32 fake = keccak256("fake");
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestNotFound.selector, fake));
        queue.getRequest(fake);
    }

    function test_isExpired_falseBeforeExpiry() public {
        bytes32 requestId = _submit();
        assertFalse(queue.isExpired(requestId));
    }

    function test_isExpired_trueAfterExpiry() public {
        bytes32 requestId = _submit();
        vm.warp(block.timestamp + EXPIRY + 1);
        assertTrue(queue.isExpired(requestId));
    }

    function test_isExpired_revertsForNonExistent() public {
        bytes32 fake = keccak256("fake");
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestNotFound.selector, fake));
        queue.isExpired(fake);
    }
}
