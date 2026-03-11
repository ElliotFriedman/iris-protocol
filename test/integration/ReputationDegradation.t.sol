// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @title ReputationDegradation
/// @notice THE KEY TEST: grant delegation -> execute OK -> bad feedback drops reputation ->
///         execution blocked -> good feedback restores -> execution OK again.
///
///         This demonstrates the novel contribution of Iris Protocol: dynamic trust boundaries
///         where an agent's delegation authority is continuously tethered to its live reputation.
contract ReputationDegradationTest is Test {
    // Contracts
    IrisAccountFactory factory;
    IrisDelegationManager dm;
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;
    ReputationGateEnforcer reputationGate;

    // Actors
    address owner;
    uint256 ownerKey;
    address agentOperator;
    uint256 agentId;

    // Account
    IrisAccount account;

    // Target
    address payable recipient;

    // The minimum score required by the delegation
    uint256 constant MIN_SCORE = 48;

    function setUp() public {
        // Deploy all infrastructure
        dm = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this)); // test contract is oracle owner
        reputationGate = new ReputationGateEnforcer();

        // Create owner keypair
        (owner, ownerKey) = makeAddrAndKey("owner");

        // Register agent (default reputation: 50)
        agentOperator = makeAddr("agentOperator");
        vm.prank(agentOperator);
        agentId = registry.registerAgent("ipfs://agent-card");
        assertEq(oracle.getReputationScore(agentId), 50);

        // Deploy smart account
        address acctAddr = factory.createAccount(owner, address(dm), 0);
        account = IrisAccount(payable(acctAddr));

        // Fund account
        vm.deal(address(account), 100 ether);

        // Recipient
        recipient = payable(makeAddr("recipient"));
    }

    /// @notice Helper to build a signed delegation with the reputation gate enforcer.
    ///         Each call uses a unique salt to produce a fresh (un-redeemed) delegation.
    function _buildDelegation(uint256 salt) internal view returns (Delegation[] memory delegations) {
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentId, MIN_SCORE)
        });

        delegations = new Delegation[](1);
        delegations[0] = Delegation({
            delegator: address(account),
            delegate: agentOperator,
            authority: address(0),
            caveats: caveats,
            salt: salt,
            signature: ""
        });

        bytes32 dHash = dm.getDelegationHash(delegations[0]);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        delegations[0].signature = abi.encodePacked(r, s, v);
    }

    /// @notice The full reputation degradation and recovery flow.
    function test_reputationDegradation_fullCycle() public {
        // =====================================================================
        // PHASE 1: Agent reputation is 50 (above MIN_SCORE=48) -- execution OK
        // =====================================================================
        {
            Delegation[] memory d1 = _buildDelegation(1);
            Action memory a1 = Action({target: recipient, value: 1 ether, callData: ""});

            vm.prank(agentOperator);
            dm.redeemDelegation(d1, a1);
            assertEq(recipient.balance, 1 ether, "Phase 1: recipient should have 1 ETH");
        }

        // =====================================================================
        // PHASE 2: Bad feedback drops reputation below threshold
        //   50 -> 45 (one negative = -5)
        // =====================================================================
        oracle.submitFeedback(agentId, false); // 50 -> 45
        assertEq(oracle.getReputationScore(agentId), 45);

        {
            Delegation[] memory d2 = _buildDelegation(2);
            Action memory a2 = Action({target: recipient, value: 1 ether, callData: ""});

            vm.prank(agentOperator);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ReputationGateEnforcer.ReputationTooLow.selector, agentId, 45, MIN_SCORE
                )
            );
            dm.redeemDelegation(d2, a2);

            // Recipient balance should NOT have changed
            assertEq(recipient.balance, 1 ether, "Phase 2: recipient should still have 1 ETH");
        }

        // =====================================================================
        // PHASE 3: More negative feedback further degrades reputation
        //   45 -> 40
        // =====================================================================
        oracle.submitFeedback(agentId, false); // 45 -> 40
        assertEq(oracle.getReputationScore(agentId), 40);

        {
            Delegation[] memory d3 = _buildDelegation(3);
            Action memory a3 = Action({target: recipient, value: 1 ether, callData: ""});

            vm.prank(agentOperator);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ReputationGateEnforcer.ReputationTooLow.selector, agentId, 40, MIN_SCORE
                )
            );
            dm.redeemDelegation(d3, a3);
        }

        // =====================================================================
        // PHASE 4: Positive feedback starts recovery but still below threshold
        //   40 -> 42 -> 44 -> 46 (three positive feedbacks, +2 each)
        // =====================================================================
        oracle.submitFeedback(agentId, true);  // 40 -> 42
        oracle.submitFeedback(agentId, true);  // 42 -> 44
        oracle.submitFeedback(agentId, true);  // 44 -> 46
        assertEq(oracle.getReputationScore(agentId), 46);

        {
            Delegation[] memory d4 = _buildDelegation(4);
            Action memory a4 = Action({target: recipient, value: 1 ether, callData: ""});

            vm.prank(agentOperator);
            vm.expectRevert(
                abi.encodeWithSelector(
                    ReputationGateEnforcer.ReputationTooLow.selector, agentId, 46, MIN_SCORE
                )
            );
            dm.redeemDelegation(d4, a4);
        }

        // =====================================================================
        // PHASE 5: One more positive feedback brings reputation to 48 (exactly at threshold)
        //   46 -> 48 -- execution is now allowed again!
        // =====================================================================
        oracle.submitFeedback(agentId, true);  // 46 -> 48
        assertEq(oracle.getReputationScore(agentId), 48);

        {
            Delegation[] memory d5 = _buildDelegation(5);
            Action memory a5 = Action({target: recipient, value: 1 ether, callData: ""});

            vm.prank(agentOperator);
            dm.redeemDelegation(d5, a5);
            assertEq(recipient.balance, 2 ether, "Phase 5: recipient should now have 2 ETH");
        }
    }

    /// @notice Verify that the delegation was never revoked -- only the reputation change
    ///         caused the block. This is the key insight: no manual revocation needed.
    function test_delegationRemainsValid_onlyReputationBlocks() public {
        // The delegation on the account side is always valid (not revoked).
        Delegation[] memory d = _buildDelegation(100);
        bytes32 dHash = dm.getDelegationHash(d[0]);

        assertTrue(account.isDelegationValid(dHash), "Delegation should be valid on account");
        assertFalse(dm.revokedDelegations(dHash), "Delegation should not be revoked on DM");

        // Drop reputation
        oracle.submitFeedback(agentId, false); // 50 -> 45

        // Delegation is still "valid" in the traditional sense
        assertTrue(account.isDelegationValid(dHash), "Delegation still valid after rep drop");
        assertFalse(dm.revokedDelegations(dHash), "Still not revoked on DM");

        // But execution is blocked by the reputation gate
        vm.prank(agentOperator);
        vm.expectRevert();
        dm.redeemDelegation(d, Action({target: recipient, value: 0.1 ether, callData: ""}));
    }
}
