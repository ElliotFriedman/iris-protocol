// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";

/// @title ReputationOracle — Formal Verification (Halmos)
/// @notice Symbolic tests proving reputation score bounds and access control invariants.
/// @dev Requires `--loop 32` (or higher) for bounded model checking of feedback loops.
///      Max loop iterations: 30 (check_score_boundedAfterManyPositive). The --loop flag
///      must exceed this value to avoid vacuous proofs.
contract ReputationOracleFV is Test {
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;
    address constant ORACLE_OWNER = address(0xBB);

    function setUp() public {
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), ORACLE_OWNER);

        // Register agent 1 so we have a valid target
        registry.registerAgent("test-agent");
    }

    // =========================================================================
    // Invariant: reputation score is always in [0, 100]
    // =========================================================================

    /// @notice Proves: after any single positive feedback, score stays <= 100.
    function check_score_cappedAt100_positive() public {
        uint256 agentId = 1;
        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, true);
        uint256 score = oracle.getReputationScore(agentId);
        assert(score <= 100);
    }

    /// @notice Proves: after any single negative feedback, score stays >= 0.
    function check_score_flooredAt0_negative() public {
        uint256 agentId = 1;
        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, false);
        uint256 score = oracle.getReputationScore(agentId);
        assert(score <= 100); // also >= 0 since uint256
    }

    /// @notice Proves: after N positive feedbacks from initial score 50, score <= 100.
    /// Uses bounded iteration (max 30 rounds = 50 + 60 = 110, but capped at 100).
    function check_score_boundedAfterManyPositive(uint8 rounds) public {
        vm.assume(rounds <= 30);
        uint256 agentId = 1;
        for (uint256 i = 0; i < rounds; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, true);
        }
        uint256 score = oracle.getReputationScore(agentId);
        assert(score >= 0 && score <= 100);
    }

    /// @notice Proves: after N negative feedbacks from initial score 50, score >= 0.
    /// Uses bounded iteration (max 12 rounds = 50 - 60, but floored at 0).
    function check_score_boundedAfterManyNegative(uint8 rounds) public {
        vm.assume(rounds <= 12);
        uint256 agentId = 1;
        for (uint256 i = 0; i < rounds; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }
        uint256 score = oracle.getReputationScore(agentId);
        assert(score <= 100);
    }

    /// @notice Proves: positive feedback increases score by exactly 2 (when not at cap).
    function check_score_positiveAdds2(uint8 preRounds) public {
        vm.assume(preRounds <= 10);
        uint256 agentId = 1;
        // Build up some score
        for (uint256 i = 0; i < preRounds; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, true);
        }
        uint256 scoreBefore = oracle.getReputationScore(agentId);
        vm.assume(scoreBefore <= 98); // not at cap

        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, true);

        uint256 scoreAfter = oracle.getReputationScore(agentId);
        assert(scoreAfter == scoreBefore + 2);
    }

    /// @notice Proves: negative feedback decreases score by exactly 5 (when score >= 5).
    function check_score_negativeSubtracts5() public {
        uint256 agentId = 1;
        // Initial score is 50, which is >= 5
        uint256 scoreBefore = oracle.getReputationScore(agentId);
        assert(scoreBefore == 50);

        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, false);

        uint256 scoreAfter = oracle.getReputationScore(agentId);
        assert(scoreAfter == 45);
    }

    // =========================================================================
    // Invariant: default score is 50
    // =========================================================================

    /// @notice Proves: any agent without feedback has score 50.
    function check_defaultScore(uint256 agentId) public view {
        uint256 score = oracle.getReputationScore(agentId);
        assert(score == 50);
    }

    // =========================================================================
    // Invariant: only authorized reviewers or owner can submit feedback
    // =========================================================================

    /// @notice Proves: unauthorized callers cannot submit feedback.
    function check_feedback_accessControl(address caller) public {
        vm.assume(caller != ORACLE_OWNER);
        uint256 agentId = 1;

        vm.prank(caller);
        try oracle.submitFeedback(agentId, true) {
            assert(false); // Must not succeed for unauthorized caller
        } catch {}
    }

    // =========================================================================
    // Invariant: feedback for unregistered agents reverts
    // =========================================================================

    /// @notice Proves: submitFeedback reverts for agent IDs that were never registered.
    function check_feedback_unregisteredReverts(uint256 agentId) public {
        vm.assume(agentId != 1); // agent 1 was registered in setUp
        vm.assume(agentId > 0); // agent 0 is never valid

        vm.prank(ORACLE_OWNER);
        try oracle.submitFeedback(agentId, true) {
            assert(false); // Must revert for unregistered agent
        } catch {}
    }

    // =========================================================================
    // Gap 1: Arithmetic consistency across multiple mixed feedbacks
    // =========================================================================

    /// @notice Proves: after P positive and N negative feedbacks, the score matches
    /// the expected formula: max(0, min(100, 50 + 2*P - 5*N)).
    /// Uses small bounded values to keep Halmos loop unrolling manageable.
    function check_score_mixedFeedbackConsistency(uint8 positives, uint8 negatives) public {
        vm.assume(positives <= 5);
        vm.assume(negatives <= 5);
        uint256 agentId = 1;

        // Submit positive feedbacks
        for (uint256 i = 0; i < positives; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, true);
        }

        // Submit negative feedbacks
        for (uint256 i = 0; i < negatives; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }

        uint256 score = oracle.getReputationScore(agentId);
        assert(score <= 100);

        // Compute expected score step by step (matching contract logic)
        uint256 expected = 50;
        for (uint256 i = 0; i < positives; i++) {
            expected = expected + 2 > 100 ? 100 : expected + 2;
        }
        for (uint256 i = 0; i < negatives; i++) {
            expected = expected < 5 ? 0 : expected - 5;
        }
        assert(score == expected);
    }

    // =========================================================================
    // Gap 2: Score lower bound — negative feedback cannot go below 0
    // =========================================================================

    /// @notice Proves: even with maximum negative feedbacks, score never underflows.
    /// Starting from 50, after 11 negative feedbacks: 50 - 55 = floored at 0.
    function check_score_cannotUnderflow() public {
        uint256 agentId = 1;

        // 11 negative feedbacks: 50 → 45 → 40 → 35 → 30 → 25 → 20 → 15 → 10 → 5 → 0 → 0
        for (uint256 i = 0; i < 11; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }

        uint256 score = oracle.getReputationScore(agentId);
        assert(score == 0);

        // One more negative feedback — should stay at 0
        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, false);
        score = oracle.getReputationScore(agentId);
        assert(score == 0);
    }

    // =========================================================================
    // Gap 3: First feedback initialization
    // =========================================================================

    /// @notice Proves: the first positive feedback on a fresh agent results in score 52
    /// (initialized to 50, then +2).
    function check_score_firstPositiveFeedback() public {
        uint256 agentId = 1;
        // Before any feedback, score is 50 (lazy default)
        assert(oracle.getReputationScore(agentId) == 50);

        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, true);

        assert(oracle.getReputationScore(agentId) == 52);
    }

    /// @notice Proves: the first negative feedback on a fresh agent results in score 45
    /// (initialized to 50, then -5).
    function check_score_firstNegativeFeedback() public {
        uint256 agentId = 1;
        assert(oracle.getReputationScore(agentId) == 50);

        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, false);

        assert(oracle.getReputationScore(agentId) == 45);
    }

    // =========================================================================
    // Gap 4: Score cap — positive feedback cannot exceed 100
    // =========================================================================

    /// @notice Proves: score cannot exceed 100 even after many positive feedbacks.
    /// Starting from 50, after 26 positive feedbacks: 50 + 52 = capped at 100.
    function check_score_cannotExceed100() public {
        uint256 agentId = 1;

        // 26 positive feedbacks: 50 + 52 = 102, but capped at 100
        // Actually: 50 → 52 → ... → 100 → 100 → 100
        for (uint256 i = 0; i < 26; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, true);
        }

        uint256 score = oracle.getReputationScore(agentId);
        assert(score == 100);

        // One more — should stay at 100
        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, true);
        score = oracle.getReputationScore(agentId);
        assert(score == 100);
    }

    // =========================================================================
    // Gap 5: Recovery from zero
    // =========================================================================

    /// @notice Proves: an agent at score 0 can recover via positive feedback.
    function check_score_recoveryFromZero() public {
        uint256 agentId = 1;

        // Drive score to 0: 50 - 50 = 0 (10 negative feedbacks)
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }
        assert(oracle.getReputationScore(agentId) == 0);

        // Recover with positive feedback: 0 → 2
        vm.prank(ORACLE_OWNER);
        oracle.submitFeedback(agentId, true);
        assert(oracle.getReputationScore(agentId) == 2);
    }
}
