// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title IrisApprovalQueue
/// @notice Approval queue for agent-initiated transactions that exceed delegation limits.
/// @dev Agents submit requests; delegators (wallet owners) approve or reject them.
///      Requests expire after a configurable duration (default 24 hours).
contract IrisApprovalQueue {
    // -------------------------------------------------------------------------
    // Types
    // -------------------------------------------------------------------------

    /// @notice A pending approval request submitted by an agent.
    struct ApprovalRequest {
        address agent;
        address target;
        bytes callData;
        uint256 value;
        bytes32 delegationHash;
        uint256 submittedAt;
        bool approved;
        bool rejected;
        bool executed;
    }

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice Duration (in seconds) after which a request expires. Default: 24 hours.
    uint256 public expiryDuration;

    /// @notice Request ID to approval request.
    mapping(bytes32 => ApprovalRequest) private _requests;

    /// @notice Request ID to delegator address.
    mapping(bytes32 => address) private _requestDelegator;

    /// @notice Delegator address to list of pending request IDs.
    mapping(address => bytes32[]) private _pendingRequests;

    /// @notice Tracks whether a request ID exists.
    mapping(bytes32 => bool) private _requestExists;

    /// @notice Nonce used for unique request ID generation.
    uint256 private _nonce;

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when an agent submits a new approval request.
    /// @param requestId The unique identifier for the request.
    /// @param agent The agent that submitted the request.
    /// @param delegator The wallet owner who must approve the request.
    /// @param target The target contract of the proposed action.
    /// @param value The ETH value of the proposed action.
    event ApprovalRequested(
        bytes32 indexed requestId,
        address indexed agent,
        address indexed delegator,
        address target,
        uint256 value
    );

    /// @notice Emitted when a delegator approves a request.
    /// @param requestId The approved request's identifier.
    /// @param delegator The delegator who approved the request.
    event ApprovalGranted(bytes32 indexed requestId, address indexed delegator);

    /// @notice Emitted when a delegator rejects a request.
    /// @param requestId The rejected request's identifier.
    /// @param delegator The delegator who rejected the request.
    event ApprovalRejected(bytes32 indexed requestId, address indexed delegator);

    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    error RequestNotFound(bytes32 requestId);
    error NotDelegator(bytes32 requestId, address caller);
    error RequestAlreadyResolved(bytes32 requestId);
    error RequestExpired(bytes32 requestId);

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------

    /// @param _expiryDuration Duration in seconds after which requests expire. Use 86400 for 24 hours.
    constructor(uint256 _expiryDuration) {
        expiryDuration = _expiryDuration;
    }

    // -------------------------------------------------------------------------
    // External — Submission
    // -------------------------------------------------------------------------

    /// @notice Submits a new approval request on behalf of the calling agent.
    /// @param target The target contract address for the proposed action.
    /// @param callData The calldata for the proposed action.
    /// @param value The ETH value for the proposed action.
    /// @param delegationHash The hash of the delegation under which this request falls.
    /// @param delegator The wallet owner who must approve or reject the request.
    /// @return requestId The unique identifier for the newly created request.
    function submitRequest(
        address target,
        bytes calldata callData,
        uint256 value,
        bytes32 delegationHash,
        address delegator
    ) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encode(msg.sender, target, value, delegationHash, block.timestamp, _nonce++));

        _requests[requestId] = ApprovalRequest({
            agent: msg.sender,
            target: target,
            callData: callData,
            value: value,
            delegationHash: delegationHash,
            submittedAt: block.timestamp,
            approved: false,
            rejected: false,
            executed: false
        });

        _requestDelegator[requestId] = delegator;
        _requestExists[requestId] = true;
        _pendingRequests[delegator].push(requestId);

        emit ApprovalRequested(requestId, msg.sender, delegator, target, value);
    }

    // -------------------------------------------------------------------------
    // External — Resolution
    // -------------------------------------------------------------------------

    /// @notice Approves a pending request. Only the delegator (wallet owner) may call this.
    /// @param requestId The identifier of the request to approve.
    function approveRequest(bytes32 requestId) external {
        _validateResolution(requestId);

        _requests[requestId].approved = true;
        emit ApprovalGranted(requestId, msg.sender);
    }

    /// @notice Rejects a pending request. Only the delegator (wallet owner) may call this.
    /// @param requestId The identifier of the request to reject.
    function rejectRequest(bytes32 requestId) external {
        _validateResolution(requestId);

        _requests[requestId].rejected = true;
        emit ApprovalRejected(requestId, msg.sender);
    }

    // -------------------------------------------------------------------------
    // External — Views
    // -------------------------------------------------------------------------

    /// @notice Returns the full ApprovalRequest struct for a given request ID.
    /// @param requestId The request to look up.
    /// @return The approval request data.
    function getRequest(bytes32 requestId) external view returns (ApprovalRequest memory) {
        if (!_requestExists[requestId]) revert RequestNotFound(requestId);
        return _requests[requestId];
    }

    /// @notice Returns all pending request IDs for a given delegator.
    /// @param delegator The wallet owner to query.
    /// @return An array of request IDs submitted for this delegator.
    function getPendingRequests(address delegator) external view returns (bytes32[] memory) {
        return _pendingRequests[delegator];
    }

    /// @notice Returns whether a request has expired.
    /// @param requestId The request to check.
    /// @return True if the request's submission time plus the expiry duration has passed.
    function isExpired(bytes32 requestId) external view returns (bool) {
        if (!_requestExists[requestId]) revert RequestNotFound(requestId);
        return block.timestamp > _requests[requestId].submittedAt + expiryDuration;
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /// @dev Validates that a request can be resolved (exists, caller is delegator, not already resolved, not expired).
    function _validateResolution(bytes32 requestId) internal view {
        if (!_requestExists[requestId]) revert RequestNotFound(requestId);
        if (_requestDelegator[requestId] != msg.sender) revert NotDelegator(requestId, msg.sender);

        ApprovalRequest storage req = _requests[requestId];
        if (req.approved || req.rejected) revert RequestAlreadyResolved(requestId);
        if (block.timestamp > req.submittedAt + expiryDuration) revert RequestExpired(requestId);
    }
}
