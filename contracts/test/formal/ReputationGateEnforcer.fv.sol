// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";

/// @title ReputationGateEnforcer — Formal Verification (Halmos)
/// @notice Symbolic tests proving the dynamic trust boundary invariant: agents below
///         the reputation threshold are always blocked, regardless of when the delegation was created.
contract ReputationGateEnforcerFV is Test {
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;
    ReputationGateEnforcer enforcer;
    address constant ORACLE_OWNER = address(0xBB);

    function setUp() public {
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), ORACLE_OWNER);
        enforcer = new ReputationGateEnforcer();

        // Register agent 1
        registry.registerAgent("formal-agent");
    }

    // =========================================================================
    // Core invariant: blocks execution when score < minScore
    // =========================================================================

    /// @notice Proves: if the oracle returns a score below minScore, beforeHook reverts.
    /// Tests with concrete oracle (IrisReputationOracle) to ensure real behavior.
    function check_gate_blocksLowReputation(uint256 minScore) public {
        vm.assume(minScore > 0);
        vm.assume(minScore <= 100);
        uint256 agentId = 1;

        // Default score is 50. If minScore > 50, should block.
        uint256 currentScore = oracle.getReputationScore(agentId);
        bytes memory terms = abi.encode(address(oracle), agentId, minScore);

        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            // Succeeded: score must be >= minScore
            assert(currentScore >= minScore);
        } catch {
            // Reverted: score must be < minScore (or terms invalid)
            // Since oracle is valid, this means score < minScore
            assert(currentScore < minScore);
        }
    }

    /// @notice Proves: reputation degradation after delegation creation blocks execution.
    /// This is the novel property — the "self-healing" trust boundary.
    function check_gate_dynamicBlockAfterDegradation() public {
        uint256 agentId = 1;
        uint256 minScore = 40;
        bytes memory terms = abi.encode(address(oracle), agentId, minScore);

        // Initial score is 50 >= 40, so the gate passes
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");

        // Degrade reputation: 3 negative feedbacks = 50 - 15 = 35 (< 40)
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }
        assert(oracle.getReputationScore(agentId) == 35);

        // Now the gate must block
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false); // Must not succeed after degradation
        } catch {}
    }

    /// @notice Proves: reputation recovery after degradation re-enables execution.
    function check_gate_recoveryReenablesAccess() public {
        uint256 agentId = 1;
        uint256 minScore = 40;
        bytes memory terms = abi.encode(address(oracle), agentId, minScore);

        // Degrade: 50 -> 35
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, false);
        }
        assert(oracle.getReputationScore(agentId) == 35);

        // Gate blocks
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false);
        } catch {}

        // Recover: 35 + 3*2 = 41 (>= 40)
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(ORACLE_OWNER);
            oracle.submitFeedback(agentId, true);
        }
        assert(oracle.getReputationScore(agentId) == 41);

        // Gate passes again
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }

    // =========================================================================
    // Invariant: zero oracle address always reverts
    // =========================================================================

    /// @notice Proves: terms with zero oracle address always reverts.
    function check_gate_zeroOracleReverts(uint256 agentId, uint256 minScore) public view {
        bytes memory terms = abi.encode(address(0), agentId, minScore);
        try enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "") {
            assert(false);
        } catch {}
    }

    // =========================================================================
    // Non-vacuity: prove the gate actually passes when it should
    // =========================================================================

    /// @notice Proves: when score >= minScore, beforeHook succeeds.
    function check_gate_nonVacuous_passesAboveThreshold() public view {
        uint256 agentId = 1;
        // Score is 50, minScore is 50 => should pass (inclusive)
        bytes memory terms = abi.encode(address(oracle), agentId, uint256(50));
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
