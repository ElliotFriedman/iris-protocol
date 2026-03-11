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
}
