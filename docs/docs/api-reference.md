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
/// @notice ERC-4337 smart contract wallet with ERC-7710 delegation support

// ──── Functions ────

function execute(address target, uint256 value, bytes calldata data) external;
function executeBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external;
function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds) external returns (uint256);
function isDelegationValid(Delegation calldata delegation) external view returns (bool);
function owner() external view returns (address);
function transferOwnership(address newOwner) external;

// ──── Events ────

event Executed(address indexed target, uint256 value, bytes data);
event BatchExecuted(address[] targets, uint256[] values);
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
event AccountInitialized(address indexed owner, address indexed entryPoint);
```

### IrisAccountFactory

```solidity
/// @title IrisAccountFactory
/// @notice Deterministic deployment factory for IrisAccount instances

function createAccount(address owner, uint256 salt) external returns (IrisAccount);
function getAddress(address owner, uint256 salt) external view returns (address);

event AccountCreated(address indexed account, address indexed owner);
```

### DelegationManager

```solidity
/// @title DelegationManager
/// @notice ERC-7710 delegation lifecycle orchestrator

// ──── Functions ────

function createDelegation(address delegate, Caveat[] calldata caveats) external returns (bytes32 delegationHash);
function signDelegation(bytes32 delegationHash, bytes calldata signature) external;
function redeemDelegation(Delegation calldata delegation, bytes calldata executionCalldata) external;
function revokeDelegation(bytes32 delegationHash) external;
function getDelegation(bytes32 delegationHash) external view returns (Delegation memory);
function isDelegationRevoked(bytes32 delegationHash) external view returns (bool);

// ──── Events ────

event DelegationCreated(bytes32 indexed delegationHash, address indexed delegator, address indexed delegate);
event DelegationSigned(bytes32 indexed delegationHash);
event DelegationRedeemed(bytes32 indexed delegationHash, address indexed delegate);
event DelegationRevoked(bytes32 indexed delegationHash);

// ──── Errors ────

error DelegationNotFound(bytes32 delegationHash);
error DelegationAlreadyRevoked(bytes32 delegationHash);
error InvalidDelegationSignature();
error UnauthorizedRedemption(address caller);
error CaveatEnforcerFailed(address enforcer, bytes reason);
```

## Caveat Enforcers

### ICaveatEnforcer (Base Interface)

```solidity
/// @title ICaveatEnforcer
/// @notice Base interface for all caveat enforcers

function beforeHook(bytes calldata terms, bytes calldata args, Delegation calldata delegation) external;
function afterHook(bytes calldata terms, bytes calldata args, Delegation calldata delegation) external;
```

### SpendingCapEnforcer

```solidity
/// @title SpendingCapEnforcer
/// @notice Enforces cumulative spending limits over configurable time periods

struct SpendingCapTerms {
    uint256 cap;       // Maximum spend in wei
    uint256 period;    // Period in seconds
}

// ──── View Functions ────

function getSpent(bytes32 delegationHash) external view returns (uint256);
function getRemainingCap(bytes32 delegationHash, bytes calldata terms) external view returns (uint256);

// ──── Errors ────

error SpendingCapExceeded(uint256 requested, uint256 remaining);
```

### ContractWhitelistEnforcer

```solidity
/// @title ContractWhitelistEnforcer
/// @notice Restricts delegated calls to approved target contracts

struct WhitelistTerms {
    address[] allowedContracts;
}

error ContractNotWhitelisted(address target);
```

### FunctionSelectorEnforcer

```solidity
/// @title FunctionSelectorEnforcer
/// @notice Restricts delegated calls to approved function selectors

struct SelectorTerms {
    bytes4[] allowedSelectors;
}

error SelectorNotAllowed(bytes4 selector);
```

### TimeWindowEnforcer

```solidity
/// @title TimeWindowEnforcer
/// @notice Limits delegation validity to a time range

struct TimeWindowTerms {
    uint256 validAfter;
    uint256 validBefore;
}

error DelegationNotYetValid(uint256 current, uint256 validAfter);
error DelegationExpired(uint256 current, uint256 validBefore);
```

### SingleTxCapEnforcer

```solidity
/// @title SingleTxCapEnforcer
/// @notice Caps maximum ETH value per transaction

struct SingleTxCapTerms {
    uint256 maxValue;
}

error SingleTxCapExceeded(uint256 value, uint256 cap);
```

### CooldownEnforcer

```solidity
/// @title CooldownEnforcer
/// @notice Enforces minimum time between large transactions

struct CooldownTerms {
    uint256 cooldownPeriod;
    uint256 valueThreshold;
}

// ──── View Functions ────

function getLastLargeTx(bytes32 delegationHash) external view returns (uint256 timestamp);

error CooldownNotElapsed(uint256 timeRemaining);
```

### ReputationGateEnforcer

```solidity
/// @title ReputationGateEnforcer
/// @notice Gates execution on real-time ERC-8004 reputation scores

struct ReputationGateTerms {
    address reputationOracle;
    uint256 minimumScore;
    address agentRegistry;
}

// ──── Events ────

event ReputationCheckPassed(address indexed agent, uint256 score, uint256 required);
event ReputationCheckFailed(address indexed agent, uint256 score, uint256 required);

// ──── Errors ────

error ReputationTooLow(address agent, uint256 score, uint256 required);
error AgentNotRegistered(address agent);
```

## Identity Contracts

### IrisAgentRegistry

```solidity
/// @title IrisAgentRegistry
/// @notice ERC-8004 agent identity registry

// ──── Functions ────

function register(string calldata metadata) external returns (uint256 tokenId);
function isRegistered(address agent) external view returns (bool);
function getTokenId(address agent) external view returns (uint256);
function getMetadata(address agent) external view returns (string memory);
function updateMetadata(string calldata newMetadata) external;

// ──── Events ────

event AgentRegistered(address indexed agent, uint256 indexed tokenId, string metadata);
event MetadataUpdated(address indexed agent, string newMetadata);

// ──── Errors ────

error AlreadyRegistered(address agent);
error NotRegistered(address agent);
```

### IrisReputationOracle

```solidity
/// @title IrisReputationOracle
/// @notice Tracks and reports agent reputation scores

struct ReputationRecord {
    uint256 timestamp;
    int256 scoreChange;
    bytes action;
    address reporter;
}

// ──── Functions ────

function getScore(address agent) external view returns (uint256 score);
function reportPositive(address agent, bytes calldata action, uint256 impact) external;
function reportNegative(address agent, bytes calldata action, uint256 impact) external;
function getHistory(address agent) external view returns (ReputationRecord[] memory);

// ──── Events ────

event ReputationUpdated(address indexed agent, uint256 oldScore, uint256 newScore, bytes action);

// ──── Errors ────

error AgentNotRegistered(address agent);
error InvalidImpactValue(uint256 impact);
error UnauthorizedReporter(address reporter);
```

## Tier Presets

### TierOnePreset

```solidity
/// @title TierOnePreset
/// @notice Supervised tier delegation factory

function createTierOneDelegation(
    IDelegationManager manager,
    address agent,
    address[] calldata approvedContracts,
    bytes4[] calldata allowedSelectors,
    uint256 validUntil
) external returns (bytes32 delegationHash);
```

### TierTwoPreset

```solidity
/// @title TierTwoPreset
/// @notice Autonomous tier delegation factory

function createTierTwoDelegation(
    IDelegationManager manager,
    address agent,
    bytes4[] calldata allowedSelectors
) external returns (bytes32 delegationHash);
```

### TierThreePreset

```solidity
/// @title TierThreePreset
/// @notice Full delegation tier factory

function createTierThreeDelegation(
    IDelegationManager manager,
    address agent
) external returns (bytes32 delegationHash);
```

## Type Reference

```solidity
/// @notice A delegation from a delegator to a delegate with caveats
struct Delegation {
    address delegator;       // The account granting the delegation
    address delegate;        // The agent receiving the delegation
    bytes32 authority;       // Parent delegation hash (for chained delegations)
    Caveat[] caveats;        // Array of caveat enforcers with terms
    uint256 salt;            // Unique salt for delegation hash
    bytes signature;         // EIP-712 signature from the delegator
}

/// @notice A caveat attached to a delegation
struct Caveat {
    address enforcer;        // The caveat enforcer contract address
    bytes terms;             // Encoded enforcer-specific configuration
}

/// @notice Packed UserOperation per ERC-4337
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
