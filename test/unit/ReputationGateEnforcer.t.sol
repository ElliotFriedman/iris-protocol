// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";

contract ReputationGateEnforcerTest is Test {
    ReputationGateEnforcer enforcer;
    IrisReputationOracle oracle;
    IrisAgentRegistry registry;
    address oracleOwner;
    address agentOperator;
    uint256 agentId;

    event ReputationCheckPassed(uint256 indexed agentId, uint256 currentScore, uint256 requiredScore);

    function setUp() public {
        enforcer = new ReputationGateEnforcer();
        oracleOwner = makeAddr("oracleOwner");
        agentOperator = makeAddr("agentOperator");

        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), oracleOwner);

        // Register an agent
        vm.prank(agentOperator);
        agentId = registry.registerAgent("ipfs://agent");
    }

    function _terms(uint256 _agentId, uint256 minScore) internal view returns (bytes memory) {
        return abi.encode(address(oracle), _agentId, minScore);
    }

    function _callBefore(bytes memory terms) internal {
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_passesWhenScoreAboveMin() public {
        // Default score is 50
        vm.expectEmit(true, false, false, true);
        emit ReputationCheckPassed(agentId, 50, 40);
        _callBefore(_terms(agentId, 40));
    }

    function test_beforeHook_passesWhenScoreEqualsMin() public {
        _callBefore(_terms(agentId, 50));
    }

    function test_beforeHook_revertsWhenScoreBelowMin() public {
        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, agentId, 50, 60)
        );
        _callBefore(_terms(agentId, 60));
    }

    function test_beforeHook_revertsForZeroOracle() public {
        bytes memory terms = abi.encode(address(0), agentId, uint256(50));
        vm.expectRevert(ReputationGateEnforcer.InvalidTerms.selector);
        _callBefore(terms);
    }

    function test_beforeHook_revertsForBadOracle() public {
        // Use an EOA as oracle -- staticcall will fail
        bytes memory terms = abi.encode(makeAddr("eoa"), agentId, uint256(50));
        vm.expectRevert(ReputationGateEnforcer.InvalidTerms.selector);
        _callBefore(terms);
    }

    function test_dynamicDegradation_blocksAfterNegativeFeedback() public {
        // Default score = 50, minScore = 48
        _callBefore(_terms(agentId, 48)); // passes at 50

        // Submit negative feedback: 50 - 5 = 45
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, false);

        vm.expectRevert(
            abi.encodeWithSelector(ReputationGateEnforcer.ReputationTooLow.selector, agentId, 45, 48)
        );
        _callBefore(_terms(agentId, 48));
    }

    function test_dynamicRecovery_allowsAfterPositiveFeedback() public {
        // Drop score to 45
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, false); // 50 -> 45

        vm.expectRevert();
        _callBefore(_terms(agentId, 48));

        // Positive feedback: 45 + 2 = 47 (still below)
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true);
        vm.expectRevert();
        _callBefore(_terms(agentId, 48));

        // More positive: 47 + 2 = 49 (above 48)
        vm.prank(oracleOwner);
        oracle.submitFeedback(agentId, true);
        _callBefore(_terms(agentId, 48)); // passes at 49
    }

    function test_afterHook_isNoop() public {
        ReputationGateEnforcer e = new ReputationGateEnforcer();
        e.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
