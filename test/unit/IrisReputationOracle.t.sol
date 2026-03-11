// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";

contract IrisReputationOracleTest is Test {
    IrisReputationOracle oracle;
    IrisAgentRegistry registry;
    address oracleOwner;
    address operator;
    address reviewer;
    address stranger;
    uint256 agentId;

    event FeedbackSubmitted(uint256 indexed agentId, address indexed reviewer, bool positive, uint256 newScore);
    event ReviewerAdded(uint256 indexed agentId, address indexed reviewer);

    function setUp() public {
        oracleOwner = makeAddr("oracleOwner");
        operator = makeAddr("operator");
        reviewer = makeAddr("reviewer");
        stranger = makeAddr("stranger");

        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), oracleOwner);

        vm.prank(operator);
        agentId = registry.registerAgent("ipfs://agent");
    }

    // -----------------------------------------------------------------------
    // getReputationScore
    // -----------------------------------------------------------------------

    function test_getReputationScore_default50() public view {
        assertEq(oracle.getReputationScore(agentId), 50);
    }

    // -----------------------------------------------------------------------
    // submitFeedback
    // -----------------------------------------------------------------------

    function test_submitFeedback_positiveAdds2() public {
        vm.prank(oracleOwner);
        vm.expectEmit(true, true, false, true);
        emit FeedbackSubmitted(agentId, oracleOwner, true, 52);
        oracle.submitFeedback(agentId, true);

        assertEq(oracle.getReputationScore(agentId), 52);
    }

    function test_submitFeedback_negativeSubtracts5() public {
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, false);
        assertEq(oracle.getReputationScore(agentId), 45);
    }

    function test_submitFeedback_cappedAt100() public {
        // Start at 50, add positive 26 times => 50 + 52 = 102, but capped at 100
        for (uint256 i = 0; i < 26; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, true);
        }
        assertEq(oracle.getReputationScore(agentId), 100);
    }

    function test_submitFeedback_flooredAt0() public {
        // Start at 50, subtract 5 eleven times => 50 - 55 = negative, floored at 0
        for (uint256 i = 0; i < 11; i++) {
            vm.prank(oracleOwner);
            oracle.submitFeedback(agentId, false);
        }
        assertEq(oracle.getReputationScore(agentId), 0);
    }

    function test_submitFeedback_revertsForUnauthorised() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.NotAuthorisedReviewer.selector, agentId, stranger)
        );
        oracle.submitFeedback(agentId, true);
    }

    function test_submitFeedback_allowedReviewerCanSubmit() public {
        vm.prank(operator);
        oracle.addReviewer(agentId, reviewer);

        vm.prank(reviewer);
        oracle.submitFeedback(agentId, true);
        assertEq(oracle.getReputationScore(agentId), 52);
    }

    // -----------------------------------------------------------------------
    // addReviewer
    // -----------------------------------------------------------------------

    function test_addReviewer_operatorCanAdd() public {
        vm.prank(operator);
        vm.expectEmit(true, true, false, false);
        emit ReviewerAdded(agentId, reviewer);
        oracle.addReviewer(agentId, reviewer);

        assertTrue(oracle.isAllowedReviewer(agentId, reviewer));
    }

    function test_addReviewer_ownerCanAdd() public {
        vm.prank(oracleOwner);
        oracle.addReviewer(agentId, reviewer);
        assertTrue(oracle.isAllowedReviewer(agentId, reviewer));
    }

    function test_addReviewer_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert(
            abi.encodeWithSelector(IrisReputationOracle.NotOperatorOrOwner.selector, agentId, stranger)
        );
        oracle.addReviewer(agentId, reviewer);
    }

    // -----------------------------------------------------------------------
    // isAllowedReviewer
    // -----------------------------------------------------------------------

    function test_isAllowedReviewer_falseByDefault() public view {
        assertFalse(oracle.isAllowedReviewer(agentId, stranger));
    }
}
