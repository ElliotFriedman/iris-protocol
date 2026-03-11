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
}
