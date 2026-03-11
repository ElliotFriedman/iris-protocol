// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../src/identity/IrisReputationOracle.sol";

contract IrisReputationOracleTest is Test {
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;

    address oracleOwner = makeAddr("oracleOwner");
    address operator = makeAddr("operator");
    address reviewer = makeAddr("reviewer");
    address stranger = makeAddr("stranger");

    uint256 agentId;

    function setUp() public {
        registry = new IrisAgentRegistry();

        vm.prank(operator);
        agentId = registry.registerAgent("ipfs://agent");

        oracle = new IrisReputationOracle(address(registry), oracleOwner);
    }

    function test_defaultScoreIs50() public view {
        assertEq(oracle.getReputationScore(agentId), 50);
    }

    function test_positiveFeedbackIncreasesScore() public {
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true);

        assertEq(oracle.getReputationScore(agentId), 52);
    }

    function test_negativeFeedbackDecreasesScore() public {
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, false);

        assertEq(oracle.getReputationScore(agentId), 45);
    }

    function test_scoreCapsAt100() public {
        // Need 25 positive feedbacks to go from 50 to 100 (25 * 2 = 50)
        for (uint256 i = 0; i < 30; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, true);
        }

        assertEq(oracle.getReputationScore(agentId), 100);
    }

    function test_scoreFloorsAtZero() public {
        // Need 10 negative feedbacks to go from 50 to 0 (10 * 5 = 50)
        for (uint256 i = 0; i < 15; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, false);
        }

        assertEq(oracle.getReputationScore(agentId), 0);
    }

    function test_revertsFeedbackFromUnauthorized() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.NotAuthorisedReviewer.selector, agentId, stranger)
        );
        oracle.submitFeedback(agentId, true);
    }

    function test_ownerCanSubmitFeedback() public {
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true);

        assertEq(oracle.getReputationScore(agentId), 52);
    }

    function test_addReviewerByOperator() public {
        vm.prank(operator);
        oracle.addReviewer(agentId, reviewer);

        assertTrue(oracle.isAllowedReviewer(agentId, reviewer));

        // Reviewer can now submit feedback
        vm.prank(reviewer);
        oracle.submitFeedback(agentId, true);

        assertEq(oracle.getReputationScore(agentId), 52);
    }

    function test_addReviewerByOwner() public {
        vm.prank(oracleOwner);
        oracle.addReviewer(agentId, reviewer);

        assertTrue(oracle.isAllowedReviewer(agentId, reviewer));
    }

    function test_addReviewerRevertsForNonOperatorNonOwner() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.NotOperatorOrOwner.selector, agentId, stranger)
        );
        oracle.addReviewer(agentId, reviewer);
    }

    // -----------------------------------------------------------------------
    // Additional branch coverage
    // -----------------------------------------------------------------------

    function test_submitFeedbackRevertsForUnregisteredAgent() public {
        // agentId 999 was never registered
        vm.prank(oracleOwner);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.AgentNotRegistered.selector, 999)
        );
        oracle.submitFeedback(999, true);
    }

    function test_submitFeedbackRevertsForDeactivatedAgent() public {
        // Deactivate the agent first
        vm.prank(operator);
        registry.deactivateAgent(agentId);

        vm.prank(oracleOwner);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.AgentNotRegistered.selector, agentId)
        );
        oracle.submitFeedback(agentId, true);
    }

    function test_getReputationScoreReturns50ForUninitialisedAgent() public view {
        // Query score for an agent that has never received feedback
        // (different from agentId which may receive feedback in other tests)
        assertEq(oracle.getReputationScore(9999), 50);
    }

    function test_positiveScoreCapsExactlyAt100() public {
        // Bring score to 99: start at 50, add 24 positive (+48) = 98, then +2 = 100
        // Actually: 50 + 25*2 = 100. Let's get to 99 by doing 24 positive (=98) then one negative (-5=93)
        // Simpler: go to 100, verify cap, add one more positive, still 100
        for (uint256 i = 0; i < 26; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, true);
        }
        // 50 + 26*2 = 102, but capped at 100
        assertEq(oracle.getReputationScore(agentId), 100);

        // One more positive should stay at 100
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true);
        assertEq(oracle.getReputationScore(agentId), 100);
    }

    function test_negativeScoreFloorsExactlyAtZero() public {
        // Bring score near zero: start at 50, 10 negatives = 0
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, false);
        }
        assertEq(oracle.getReputationScore(agentId), 0);

        // Score is 0, subtract again should stay at 0 (score < 5 branch)
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, false);
        assertEq(oracle.getReputationScore(agentId), 0);
    }

    function test_ensureInitialisedOnlyRunsOnce() public {
        // First feedback initialises to 50 then applies
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true); // 50 + 2 = 52

        // Second feedback should not re-initialise to 50
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true); // 52 + 2 = 54

        assertEq(oracle.getReputationScore(agentId), 54);
    }
}
