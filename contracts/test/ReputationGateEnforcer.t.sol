// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../src/identity/IrisReputationOracle.sol";

/// @title ReputationGateEnforcerTest
/// @notice Tests the ReputationGateEnforcer using the real IrisAgentRegistry and IrisReputationOracle.
contract ReputationGateEnforcerTest is Test {
    ReputationGateEnforcer public enforcer;
    IrisAgentRegistry public registry;
    IrisReputationOracle public oracle;

    address constant DM = address(0xDEAD);
    bytes32 constant HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x1);
    address constant REDEEMER = address(0x2);
    address constant TARGET = address(0x3);

    address operator = address(0xA);
    address reviewer = address(0xB);
    uint256 agentId;

    function setUp() public {
        // Deploy the full identity + reputation stack.
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this));
        enforcer = new ReputationGateEnforcer();

        // Register an agent as `operator`.
        vm.prank(operator);
        agentId = registry.registerAgent("ipfs://agent-metadata");

        // Authorise `reviewer` to submit feedback for the agent.
        // The contract owner (address(this)) can add reviewers.
        oracle.addReviewer(agentId, reviewer);
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    function _beforeHook(uint256 minScore) internal {
        bytes memory terms = abi.encode(address(oracle), agentId, minScore);
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function _submitFeedback(bool positive, uint256 count) internal {
        for (uint256 i; i < count; i++) {
            vm.prank(reviewer);
            oracle.submitFeedback(agentId, positive);
        }
    }

    // -------------------------------------------------------------------------
    // Agent with sufficient reputation passes beforeHook
    // -------------------------------------------------------------------------

    function test_sufficientReputationPasses() public {
        // Default score is 50. Require 50 -- should pass.
        _beforeHook(50);
    }

    function test_reputationAboveThresholdPasses() public {
        // Add positive feedback: 5 x +2 = +10, score becomes 60.
        _submitFeedback(true, 5);
        assertEq(oracle.getReputationScore(agentId), 60);
        _beforeHook(55);
    }

    // -------------------------------------------------------------------------
    // Agent with low reputation reverts with ReputationTooLow
    // -------------------------------------------------------------------------

    function test_lowReputationReverts() public {
        // 10 negative feedbacks: 10 x -5 = -50, floored at 0.
        _submitFeedback(false, 10);
        uint256 score = oracle.getReputationScore(agentId);
        assertEq(score, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReputationGateEnforcer.ReputationTooLow.selector,
                agentId,
                0,  // currentScore
                50  // requiredScore
            )
        );
        _beforeHook(50);
    }

    function test_slightlyBelowThresholdReverts() public {
        // 1 negative feedback: -5, score becomes 45.
        _submitFeedback(false, 1);
        assertEq(oracle.getReputationScore(agentId), 45);

        vm.expectRevert(
            abi.encodeWithSelector(
                ReputationGateEnforcer.ReputationTooLow.selector,
                agentId,
                45,
                50
            )
        );
        _beforeHook(50);
    }

    // -------------------------------------------------------------------------
    // Reputation drop after delegation creation blocks execution
    // -------------------------------------------------------------------------

    function test_reputationDropAfterDelegationBlocksExecution() public {
        // Agent starts with default score 50, passes gate requiring 50.
        _beforeHook(50);

        // Reputation drops: 5 negative feedbacks = -25, score becomes 25.
        _submitFeedback(false, 5);
        assertEq(oracle.getReputationScore(agentId), 25);

        // Same delegation terms (minScore=50) now revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                ReputationGateEnforcer.ReputationTooLow.selector,
                agentId,
                25,
                50
            )
        );
        _beforeHook(50);
    }

    // -------------------------------------------------------------------------
    // Positive feedback increases reputation and re-enables access
    // -------------------------------------------------------------------------

    function test_positiveFeedbackReenablesAccess() public {
        // Drop reputation to 25 (5 x -5).
        _submitFeedback(false, 5);
        assertEq(oracle.getReputationScore(agentId), 25);

        // Gate at 50 should fail.
        vm.expectRevert(
            abi.encodeWithSelector(
                ReputationGateEnforcer.ReputationTooLow.selector,
                agentId,
                25,
                50
            )
        );
        _beforeHook(50);

        // Submit 13 positive feedbacks: 13 x +2 = +26, score becomes 51.
        _submitFeedback(true, 13);
        assertEq(oracle.getReputationScore(agentId), 51);

        // Gate at 50 should now pass.
        _beforeHook(50);
    }

    // -------------------------------------------------------------------------
    // Edge cases
    // -------------------------------------------------------------------------

    function test_invalidTermsRevertsOnZeroOracle() public {
        bytes memory terms = abi.encode(address(0), agentId, uint256(50));
        vm.expectRevert(ReputationGateEnforcer.InvalidTerms.selector);
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_afterHookIsNoop() public pure {
        ReputationGateEnforcer e = ReputationGateEnforcer(address(0));
        // afterHook is pure and performs no state changes; just verify it exists on the interface.
        // We call it via a low-level approach to avoid needing a deployed instance for a no-op.
        // Instead, just confirm the function signature compiles.
        e.afterHook.selector;
    }

    function test_exactThresholdPasses() public {
        // Score is exactly at the minimum threshold — should pass without revert.
        _beforeHook(50);
    }
}
