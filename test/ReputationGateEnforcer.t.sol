// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";

/// @title MockReputationOracle
/// @notice A mock ERC-8004 reputation oracle for testing the ReputationGateEnforcer.
contract MockReputationOracle {
    mapping(uint256 => uint256) public scores;

    function setScore(uint256 agentId, uint256 score) external {
        scores[agentId] = score;
    }

    function getReputationScore(uint256 agentId) external view returns (uint256) {
        return scores[agentId];
    }
}

/// @title ReputationGateEnforcerTest
/// @notice Comprehensive tests for the ReputationGateEnforcer -- the core novel contribution of Iris Protocol.
contract ReputationGateEnforcerTest is Test {
    ReputationGateEnforcer public enforcer;
    MockReputationOracle public oracle;

    address constant DELEGATION_MANAGER = address(0xDEAD);
    bytes32 constant DELEGATION_HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x1);
    address constant REDEEMER = address(0x2);
    address constant TARGET = address(0x3);

    function setUp() public {
        enforcer = new ReputationGateEnforcer();
        oracle = new MockReputationOracle();
    }

    // -------------------------------------------------------------------------
    // Happy path: reputation above threshold
    // -------------------------------------------------------------------------

    function test_beforeHook_passesWhenReputationAboveThreshold() public {
        oracle.setScore(1, 80);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_passesWhenReputationExactlyAtThreshold() public {
        oracle.setScore(1, 50);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_passesWithMaxScore() public {
        oracle.setScore(1, 100);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(100));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_passesWithZeroThreshold() public {
        oracle.setScore(1, 0);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(0));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Reverts: reputation below threshold
    // -------------------------------------------------------------------------

    function test_beforeHook_revertsWhenReputationBelowThreshold() public {
        oracle.setScore(1, 49);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, 49, 50)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_revertsWithZeroReputation() public {
        oracle.setScore(1, 0);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, 0, 50)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_revertsWhenScoreOneBelow() public {
        oracle.setScore(1, 74);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(75));
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, 74, 75)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Dynamic reputation: score drops after delegation was granted
    // -------------------------------------------------------------------------

    function test_beforeHook_blocksAfterReputationDrops() public {
        oracle.setScore(1, 80);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));

        // First call passes.
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");

        // Reputation drops below threshold.
        oracle.setScore(1, 30);

        // Second call reverts -- the gate is dynamic, not static.
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, 30, 50)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_allowsAfterReputationRecovers() public {
        oracle.setScore(1, 30);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));

        vm.expectRevert();
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");

        oracle.setScore(1, 60);
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Edge cases: invalid terms
    // -------------------------------------------------------------------------

    function test_beforeHook_revertsWithZeroAddressOracle() public {
        bytes memory terms = abi.encode(address(0), uint256(1), uint256(50));
        vm.expectRevert(ReputationGateEnforcer.InvalidTerms.selector);
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_beforeHook_revertsWhenOracleIsEOA() public {
        address eoa = address(0x9999);
        bytes memory terms = abi.encode(eoa, uint256(1), uint256(50));
        vm.expectRevert(ReputationGateEnforcer.InvalidTerms.selector);
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Tier thresholds
    // -------------------------------------------------------------------------

    function test_tierOneThreshold() public {
        oracle.setScore(1, 50);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_tierTwoThreshold() public {
        oracle.setScore(1, 75);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(75));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_tierThreeThreshold() public {
        oracle.setScore(1, 90);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(90));
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    function test_tierTwoThreshold_failsForTierOneAgent() public {
        oracle.setScore(1, 55);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(75));
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, 55, 75)
        );
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Multiple agents, same enforcer
    // -------------------------------------------------------------------------

    function test_multipleAgentsDifferentScores() public {
        oracle.setScore(1, 80);
        oracle.setScore(2, 30);

        bytes memory terms1 = abi.encode(address(oracle), uint256(1), uint256(50));
        bytes memory terms2 = abi.encode(address(oracle), uint256(2), uint256(50));

        enforcer.beforeHook(terms1, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");

        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 2, 30, 50)
        );
        enforcer.beforeHook(terms2, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // afterHook is a no-op
    // -------------------------------------------------------------------------

    function test_afterHook_noop() public view {
        enforcer.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }

    // -------------------------------------------------------------------------
    // Event emission
    // -------------------------------------------------------------------------

    function test_emitsReputationCheckPassedEvent() public {
        oracle.setScore(1, 80);
        bytes memory terms = abi.encode(address(oracle), uint256(1), uint256(50));

        vm.expectEmit(true, false, false, true);
        emit ReputationGateEnforcer.ReputationCheckPassed(1, 80, 50);

        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }

    // -------------------------------------------------------------------------
    // Fuzz test
    // -------------------------------------------------------------------------

    function testFuzz_reputationGate(uint256 score, uint256 threshold) public {
        score = bound(score, 0, 100);
        threshold = bound(threshold, 0, 100);

        oracle.setScore(1, score);
        bytes memory terms = abi.encode(address(oracle), uint256(1), threshold);

        if (score < threshold) {
            vm.expectRevert(
                abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, 1, score, threshold)
            );
        }
        enforcer.beforeHook(terms, "", DELEGATION_MANAGER, DELEGATION_HASH, DELEGATOR, REDEEMER, TARGET, 0, "");
    }
}
