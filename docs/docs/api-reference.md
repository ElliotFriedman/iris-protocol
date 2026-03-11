---
sidebar_position: 9
title: API Reference
---

# API Reference

Complete Solidity interface reference for all Iris Protocol contracts.

## Core Contracts

### IrisAccount

```solidity
/// @title IrisAccount
/// @notice ERC-4337 smart contract wallet with ERC-7710 delegation support (IERC7710Delegator)

// ──── Constructor ────

constructor(address _owner, address _delegationManager);

// ──── Functions ────

function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory result);
function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas) external returns (bytes[] memory results);
function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256 validationData);
function isDelegationValid(bytes32 delegationHash) external view returns (bool);
function revokeDelegation(bytes32 delegationHash) external;
function setDelegationManager(address _delegationManager) external;
function owner() external view returns (address);
function delegationManager() external view returns (address);

// ──── Events ────

event DelegationManagerSet(address indexed oldManager, address indexed newManager);
event DelegationRevoked(bytes32 indexed delegationHash);

// ──── Errors ────

error OnlyOwner();
error OnlyOwnerOrDelegationManager();
error ExecutionFailed();
error InvalidSignatureLength();
```

### IrisAccountFactory

```solidity
/// @title IrisAccountFactory
/// @notice Deterministic deployment factory for IrisAccount instances via CREATE2

function createAccount(address owner, address delegationManager, uint256 salt) external returns (address account);
function getAddress(address owner, address delegationManager, uint256 salt) external view returns (address predicted);

event AccountCreated(address indexed account, address indexed owner);
```

### IrisDelegationManager

```solidity
/// @title IrisDelegationManager
/// @notice ERC-7710 delegation lifecycle manager with EIP-712 typed data signing

// ──── Functions ────

function redeemDelegation(Delegation[] calldata delegations, Action calldata action) external;
function revokeDelegation(Delegation calldata delegation) external;
function getDelegationHash(Delegation calldata delegation) external view returns (bytes32);
function domainSeparator() external view returns (bytes32);

// ──── Storage ────

mapping(bytes32 => bool) public revokedDelegations;

// ──── Events ────

event DelegationRedeemed(bytes32 indexed delegationHash, address indexed delegator, address indexed delegate);
event DelegationRevoked(bytes32 indexed delegationHash, address indexed delegator);

// ──── Errors ────

error EmptyDelegationChain();
error DelegationIsRevoked(bytes32 delegationHash);
error InvalidSignature();
error InvalidDelegationChain();
error NotDelegatorOrOwner();
error ExecutionFailed();
error ManagerNotAuthorized();
```

### IrisApprovalQueue

```solidity
/// @title IrisApprovalQueue
/// @notice Approval queue for agent transactions that exceed delegation limits

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

// ──── Functions ────

function submitRequest(address target, bytes calldata callData, uint256 value, bytes32 delegationHash, address delegator) external returns (bytes32 requestId);
function approveRequest(bytes32 requestId) external;
function rejectRequest(bytes32 requestId) external;
function getRequest(bytes32 requestId) external view returns (ApprovalRequest memory);
function getPendingRequests(address delegator) external view returns (bytes32[] memory);
function isExpired(bytes32 requestId) external view returns (bool);
function expiryDuration() external view returns (uint256);

// ──── Events ────

event ApprovalRequested(bytes32 indexed requestId, address indexed agent, address indexed delegator, address target, uint256 value);
event ApprovalGranted(bytes32 indexed requestId, address indexed delegator);
event ApprovalRejected(bytes32 indexed requestId, address indexed delegator);

// ──── Errors ────

error RequestNotFound(bytes32 requestId);
error NotDelegator(bytes32 requestId, address caller);
error RequestAlreadyResolved(bytes32 requestId);
error RequestExpired(bytes32 requestId);
```

## Caveat Enforcers

### ICaveatEnforcer (Base Interface)

```solidity
/// @title ICaveatEnforcer
/// @notice Base interface for all caveat enforcers

function beforeHook(
    bytes calldata terms,
    bytes calldata args,
    address delegationManager,
    bytes32 delegationHash,
    address delegator,
    address redeemer,
    address target,
    uint256 value,
    bytes calldata callData
) external;

function afterHook(
    bytes calldata terms,
    bytes calldata args,
    address delegationManager,
    bytes32 delegationHash,
    address delegator,
    address redeemer,
    address target,
    uint256 value,
    bytes calldata callData
) external;
```

### SpendingCapEnforcer

```solidity
/// @title SpendingCapEnforcer
/// @notice Enforces cumulative spending limits over configurable rolling periods

// Terms encoding: abi.encode(uint256 allowance, uint256 period)
//   - allowance: Maximum spend in wei per period
//   - period: Period length in seconds (86400 = daily, 604800 = weekly)

// ──── Storage ────

mapping(bytes32 => mapping(uint256 => uint256)) public periodSpend;

// ──── Errors ────

error SpendingCapExceeded(uint256 requested, uint256 remaining);
```

### ContractWhitelistEnforcer

```solidity
/// @title ContractWhitelistEnforcer
/// @notice Restricts delegated calls to approved target contracts

// Terms encoding: abi.encode(address[] allowedContracts)

error ContractNotWhitelisted(address target);
```

### FunctionSelectorEnforcer

```solidity
/// @title FunctionSelectorEnforcer
/// @notice Restricts delegated calls to approved function selectors

// Terms encoding: abi.encode(bytes4[] allowedSelectors)

error SelectorNotAllowed(bytes4 selector);
```

### TimeWindowEnforcer

```solidity
/// @title TimeWindowEnforcer
/// @notice Limits delegation validity to a time range

// Terms encoding: abi.encode(uint256 notBefore, uint256 notAfter)

error DelegationNotYetValid(uint256 current, uint256 validAfter);
error DelegationExpired(uint256 current, uint256 validBefore);
```

### SingleTxCapEnforcer

```solidity
/// @title SingleTxCapEnforcer
/// @notice Caps maximum ETH value per transaction

// Terms encoding: abi.encode(uint256 maxValue)

error SingleTxCapExceeded(uint256 value, uint256 cap);
```

### CooldownEnforcer

```solidity
/// @title CooldownEnforcer
/// @notice Enforces minimum time between large transactions

// Terms encoding: abi.encode(uint256 cooldownPeriod, uint256 valueThreshold)
//   - cooldownPeriod: Minimum seconds between qualifying transactions
//   - valueThreshold: Only transactions with value >= threshold trigger cooldown

// ──── Storage ────

mapping(bytes32 => uint256) public lastExecution;

error CooldownNotElapsed(uint256 nextAllowed, uint256 current);
```

### ReputationGateEnforcer

```solidity
/// @title ReputationGateEnforcer
/// @notice Gates execution on real-time ERC-8004 reputation scores

// Terms encoding: abi.encode(address reputationOracle, uint256 agentId, uint256 minScore)
//   - reputationOracle: Address of a contract exposing getReputationScore(uint256)
//   - agentId: The ERC-8004 identity token ID of the agent
//   - minScore: Minimum reputation score (0-100) required for execution

// ──── Errors ────

error ReputationTooLow(uint256 agentId, uint256 currentScore, uint256 requiredScore);
error InvalidTerms();
```

## Identity Contracts

### IrisAgentRegistry

```solidity
/// @title IrisAgentRegistry
/// @notice ERC-8004 agent identity registry with lightweight NFT ownership

struct AgentInfo {
    address operator;
    string metadataURI;
    bool active;
    uint256 registeredAt;
}

// ──── Functions ────

function registerAgent(string calldata metadataURI) external returns (uint256 agentId);
function deactivateAgent(uint256 agentId) external;
function getAgent(uint256 agentId) external view returns (AgentInfo memory);
function isRegistered(uint256 agentId) external view returns (bool);
function ownerOf(uint256 agentId) external view returns (address);

// ──── Events ────

event AgentRegistered(uint256 indexed agentId, address indexed operator, string metadataURI);
event AgentDeactivated(uint256 indexed agentId, address indexed operator);

// ──── Errors ────

error AgentNotFound(uint256 agentId);
error NotOperator(uint256 agentId, address caller);
error AgentAlreadyInactive(uint256 agentId);
```

### IrisReputationOracle

```solidity
/// @title IrisReputationOracle
/// @notice Tracks agent reputation scores (0-100). Ownable for bootstrapping.
/// @dev Positive feedback: +2 (capped at 100). Negative feedback: -5 (floored at 0). Default score: 50.

// ──── Functions ────

function submitFeedback(uint256 agentId, bool positive) external;
function addReviewer(uint256 agentId, address reviewer) external;
function getReputationScore(uint256 agentId) external view returns (uint256);
function isAllowedReviewer(uint256 agentId, address reviewer) external view returns (bool);
function agentRegistry() external view returns (IrisAgentRegistry);

// ──── Events ────

event FeedbackSubmitted(uint256 indexed agentId, address indexed reviewer, bool positive, uint256 newScore);
event ReviewerAdded(uint256 indexed agentId, address indexed reviewer);

// ──── Errors ────

error NotAuthorisedReviewer(uint256 agentId, address caller);
error NotOperatorOrOwner(uint256 agentId, address caller);
error AgentNotRegistered(uint256 agentId);
```

## Tier Presets

Tier presets are Solidity **libraries** (not deployed contracts) that return a `Caveat[]` array for building delegations.

### TierOne (Supervised) -- 4 Caveats

```solidity
library TierOne {
    function configureTierOne(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 dailyCap,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation
    ) internal view returns (Caveat[] memory caveats);
}
```

### TierTwo (Autonomous) -- 5 Caveats

```solidity
library TierTwo {
    function configureTierTwo(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address singleTxCapEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 dailyCap,
        uint256 maxTxValue,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation
    ) internal view returns (Caveat[] memory caveats);
}
```

### TierThree (Full Delegation) -- 6 Caveats

```solidity
library TierThree {
    struct Enforcers {
        address spendingCapEnforcer;
        address whitelistEnforcer;
        address timeWindowEnforcer;
        address reputationGateEnforcer;
        address singleTxCapEnforcer;
        address cooldownEnforcer;
    }

    struct Params {
        address reputationOracle;
        uint256 agentId;
        uint256 weeklyCap;
        uint256 maxTxValue;
        address[] allowedContracts;
        uint256 validUntil;
        uint256 minReputation;
        uint256 cooldownPeriod;
        uint256 cooldownThreshold;
    }

    function configureTierThree(
        Enforcers memory enforcers,
        Params memory params
    ) internal view returns (Caveat[] memory caveats);
}
```

## Type Reference

```solidity
/// @notice A delegation from a delegator to a delegate with caveats
struct Delegation {
    address delegator;       // The account granting the delegation
    address delegate;        // The agent receiving the delegation
    address authority;       // Parent delegation hash (address(0) for root)
    Caveat[] caveats;        // Array of caveat enforcers with terms
    uint256 salt;            // Unique salt for delegation hash
    bytes signature;         // EIP-712 signature from the delegator's owner
}

/// @notice A caveat attached to a delegation
struct Caveat {
    address enforcer;        // The caveat enforcer contract address
    bytes terms;             // ABI-encoded enforcer-specific configuration
}

/// @notice An action to execute via delegation
struct Action {
    address target;          // Target contract address
    uint256 value;           // ETH value to send
    bytes callData;          // Calldata to execute
}

/// @notice Packed UserOperation per ERC-4337 v0.7
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
```
