// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";

import {IrisAccount} from "../src/IrisAccount.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../src/caveats/ContractWhitelistEnforcer.sol";
import {TimeWindowEnforcer} from "../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../src/caveats/ReputationGateEnforcer.sol";
import {SingleTxCapEnforcer} from "../src/caveats/SingleTxCapEnforcer.sol";
import {FunctionSelectorEnforcer} from "../src/caveats/FunctionSelectorEnforcer.sol";
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";

/// @notice Simple target contract for integration tests.
contract MockTarget {
    uint256 public value;

    function setValue(uint256 v) external payable {
        value = v;
    }

    receive() external payable {}
}

/// @title Iris Protocol Integration Tests
/// @notice End-to-end tests demonstrating the full delegation lifecycle: registration, signing,
///         redemption, caveat enforcement, reputation gating, and revocation.
contract IntegrationTest is Test {
    // -------------------------------------------------------------------------
    // Protocol contracts
    // -------------------------------------------------------------------------

    IrisAccountFactory factory;
    IrisDelegationManager delegationManager;
    IrisAgentRegistry agentRegistry;
    IrisReputationOracle reputationOracle;

    // Caveat enforcers
    SpendingCapEnforcer spendingCap;
    ContractWhitelistEnforcer contractWhitelist;
    TimeWindowEnforcer timeWindow;
    ReputationGateEnforcer reputationGate;
    SingleTxCapEnforcer singleTxCap;
    FunctionSelectorEnforcer functionSelector;

    // Target
    MockTarget target;

    // Wallets (address + private key)
    address user;
    uint256 userKey;
    address agent;
    uint256 agentKey;

    // The user's smart account
    IrisAccount userAccount;

    // -------------------------------------------------------------------------
    // Setup
    // -------------------------------------------------------------------------

    function setUp() public {
        // Create wallets for signing
        (user, userKey) = makeAddrAndKey("user");
        (agent, agentKey) = makeAddrAndKey("agent");

        // Deploy core protocol
        delegationManager = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        agentRegistry = new IrisAgentRegistry();
        reputationOracle = new IrisReputationOracle(address(agentRegistry), address(this));

        // Deploy enforcers
        spendingCap = new SpendingCapEnforcer();
        contractWhitelist = new ContractWhitelistEnforcer();
        timeWindow = new TimeWindowEnforcer();
        reputationGate = new ReputationGateEnforcer();
        singleTxCap = new SingleTxCapEnforcer();
        functionSelector = new FunctionSelectorEnforcer();

        // Deploy mock target
        target = new MockTarget();
    }

    // =========================================================================
    //  Helpers
    // =========================================================================

    /// @dev External wrapper so that getDelegationHash receives calldata (not memory).
    function helperGetHash(Delegation calldata delegation) external view returns (bytes32) {
        return delegationManager.getDelegationHash(delegation);
    }

    /// @dev Signs a delegation with the given private key and returns the complete Delegation
    ///      with the signature field populated.
    function _signDelegation(Delegation memory delegation, uint256 privateKey)
        internal
        view
        returns (Delegation memory)
    {
        bytes32 hash = this.helperGetHash(delegation);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, hash);
        delegation.signature = abi.encodePacked(r, s, v);
        return delegation;
    }

    /// @dev Creates a user smart account via the factory, funds it, and returns it.
    function _createFundedAccount() internal returns (IrisAccount) {
        address accountAddr = factory.createAccount(user, address(delegationManager), 0);
        IrisAccount account = IrisAccount(payable(accountAddr));
        vm.deal(accountAddr, 100 ether);
        return account;
    }

    /// @dev Registers the agent on the registry (pranking as agent) and returns the agentId.
    function _registerAgent() internal returns (uint256 agentId) {
        vm.prank(agent);
        agentId = agentRegistry.registerAgent("ipfs://agent-metadata");
    }

    /// @dev Wraps a single delegation into a Delegation[] for redeemDelegation.
    function _asSingletonChain(Delegation memory d) internal pure returns (Delegation[] memory chain) {
        chain = new Delegation[](1);
        chain[0] = d;
    }

    /// @dev Redeems a delegation chain as the agent.
    function _redeemAsAgent(Delegation[] memory chain, Action memory action) internal {
        vm.prank(agent);
        delegationManager.redeemDelegation(chain, action);
    }

    // =========================================================================
    //  test_fullDemoFlow
    // =========================================================================

    /// @notice Complete 10-step demo: deploy, register, create account, delegate with 4 caveats,
    ///         successful execution, spending cap rejection, reputation drop rejection, revocation.
    function test_fullDemoFlow() public {
        // -------------------------------------------------------------------
        // Step 1: All contracts deployed in setUp()
        // -------------------------------------------------------------------

        // -------------------------------------------------------------------
        // Step 2: Agent registers on IrisAgentRegistry
        // -------------------------------------------------------------------
        uint256 agentId = _registerAgent();
        assertEq(agentId, 1, "First agent should get ID 1");
        assertTrue(agentRegistry.isRegistered(agentId), "Agent should be registered");

        // -------------------------------------------------------------------
        // Step 3: User creates an IrisAccount via factory
        // -------------------------------------------------------------------
        userAccount = _createFundedAccount();
        assertEq(userAccount.owner(), user, "Account owner mismatch");
        assertEq(userAccount.delegationManager(), address(delegationManager), "DelegationManager mismatch");

        // -------------------------------------------------------------------
        // Step 4: Build Tier 1 caveats
        // -------------------------------------------------------------------
        Caveat[] memory caveats = new Caveat[](4);

        // SpendingCap: 1 ether per day (86400 seconds)
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(1 ether), uint256(86400))});

        // ContractWhitelist: MockTarget only
        address[] memory allowedTargets = new address[](1);
        allowedTargets[0] = address(target);
        caveats[1] = Caveat({enforcer: address(contractWhitelist), terms: abi.encode(allowedTargets)});

        // TimeWindow: now to now + 7 days
        caveats[2] =
            Caveat({enforcer: address(timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 7 days)});

        // ReputationGate: minimum score 40
        caveats[3] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, uint256(40))
        });

        // -------------------------------------------------------------------
        // Step 5: User signs the delegation to the agent
        // -------------------------------------------------------------------
        Delegation memory delegation = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });
        delegation = _signDelegation(delegation, userKey);

        Delegation[] memory chain = _asSingletonChain(delegation);

        // -------------------------------------------------------------------
        // Step 6: Agent redeems delegation - setValue(42) with 0.5 ether
        // -------------------------------------------------------------------
        Action memory action =
            Action({target: address(target), value: 0.5 ether, callData: abi.encodeCall(MockTarget.setValue, (42))});

        _redeemAsAgent(chain, action);
        assertEq(target.value(), 42, "MockTarget value should be 42");
        assertEq(address(target).balance, 0.5 ether, "MockTarget should hold 0.5 ether");

        // -------------------------------------------------------------------
        // Step 7: Agent tries 2 ether - SpendingCap blocks (0.5 already spent, total 2.5 > 1)
        // -------------------------------------------------------------------
        Action memory bigAction =
            Action({target: address(target), value: 2 ether, callData: abi.encodeCall(MockTarget.setValue, (99))});

        vm.prank(agent);
        vm.expectRevert(); // SpendingCapExceeded
        delegationManager.redeemDelegation(chain, bigAction);

        // -------------------------------------------------------------------
        // Step 8: Reputation drops below 40 via negative feedback
        // -------------------------------------------------------------------
        // Default score is 50. Each negative feedback subtracts 5.
        // 3 negatives: 50 -> 45 -> 40 -> 35 (below 40).
        reputationOracle.submitFeedback(agentId, false); // 50 -> 45
        reputationOracle.submitFeedback(agentId, false); // 45 -> 40
        reputationOracle.submitFeedback(agentId, false); // 40 -> 35
        assertEq(reputationOracle.getReputationScore(agentId), 35, "Score should be 35");

        // -------------------------------------------------------------------
        // Step 9: Agent attempts execution - ReputationGate blocks
        // -------------------------------------------------------------------
        // Fresh delegation with new salt so spending cap state is clean.
        Delegation memory delegation2 = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 2,
            signature: ""
        });
        delegation2 = _signDelegation(delegation2, userKey);
        Delegation[] memory chain2 = _asSingletonChain(delegation2);

        Action memory smallAction =
            Action({target: address(target), value: 0.1 ether, callData: abi.encodeCall(MockTarget.setValue, (7))});

        vm.prank(agent);
        vm.expectRevert(); // ReputationTooLow
        delegationManager.redeemDelegation(chain2, smallAction);

        // -------------------------------------------------------------------
        // Step 10: User revokes delegation - agent can no longer redeem
        // -------------------------------------------------------------------
        // Restore reputation above 40 so revocation is the blocking factor.
        reputationOracle.submitFeedback(agentId, true); // 35 -> 37
        reputationOracle.submitFeedback(agentId, true); // 37 -> 39
        reputationOracle.submitFeedback(agentId, true); // 39 -> 41

        // Revoke the delegation hash via the delegation manager.
        bytes32 delegationHash = this.helperGetHash(delegation2);
        vm.prank(user);
        delegationManager.revokeDelegation(delegationHash);

        vm.prank(agent);
        vm.expectRevert(); // DelegationIsRevoked
        delegationManager.redeemDelegation(chain2, smallAction);
    }

    // =========================================================================
    //  test_delegationRevocation
    // =========================================================================

    /// @notice Tests that revoking a delegation hash prevents future redemptions.
    function test_delegationRevocation() public {
        _registerAgent();
        userAccount = _createFundedAccount();

        // Simple delegation with no caveats.
        Caveat[] memory noCaveats = new Caveat[](0);
        Delegation memory delegation = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: noCaveats,
            salt: 100,
            signature: ""
        });
        delegation = _signDelegation(delegation, userKey);
        Delegation[] memory chain = _asSingletonChain(delegation);

        // Successful redemption.
        Action memory action =
            Action({target: address(target), value: 0, callData: abi.encodeCall(MockTarget.setValue, (1))});
        _redeemAsAgent(chain, action);
        assertEq(target.value(), 1, "setValue should have succeeded");

        // Revoke via the delegation manager.
        bytes32 hash = this.helperGetHash(delegation);
        vm.prank(user);
        delegationManager.revokeDelegation(hash);
        assertTrue(delegationManager.revokedDelegations(hash), "Delegation should be revoked");

        // Attempt to redeem again -- should revert with DelegationIsRevoked.
        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(IrisDelegationManager.DelegationIsRevoked.selector, hash));
        delegationManager.redeemDelegation(chain, action);
    }

    // =========================================================================
    //  test_reputationGatedUpgrade
    // =========================================================================

    /// @notice Demonstrates tiered delegation: an agent unlocks higher-privilege delegations as
    ///         its reputation score increases.
    function test_reputationGatedUpgrade() public {
        uint256 agentId = _registerAgent();
        userAccount = _createFundedAccount();

        // -------------------------------------------------------------------
        // Step 1: Agent starts with default reputation (50)
        // -------------------------------------------------------------------
        assertEq(reputationOracle.getReputationScore(agentId), 50, "Default score should be 50");

        // -------------------------------------------------------------------
        // Step 2: Tier 1 delegation - minReputation = 40 - agent CAN use it (50 >= 40)
        // -------------------------------------------------------------------
        Caveat[] memory tier1Caveats = new Caveat[](1);
        tier1Caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, uint256(40))
        });

        Delegation memory tier1 = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: tier1Caveats,
            salt: 200,
            signature: ""
        });
        tier1 = _signDelegation(tier1, userKey);

        Action memory action =
            Action({target: address(target), value: 0, callData: abi.encodeCall(MockTarget.setValue, (10))});

        _redeemAsAgent(_asSingletonChain(tier1), action);
        assertEq(target.value(), 10, "Tier 1 execution should succeed");

        // -------------------------------------------------------------------
        // Step 3: Tier 2 delegation - minReputation = 70 - agent CANNOT use it (50 < 70)
        // -------------------------------------------------------------------
        Caveat[] memory tier2Caveats = new Caveat[](1);
        tier2Caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(reputationOracle), agentId, uint256(70))
        });

        Delegation memory tier2 = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: tier2Caveats,
            salt: 201,
            signature: ""
        });
        tier2 = _signDelegation(tier2, userKey);

        Action memory action2 =
            Action({target: address(target), value: 0, callData: abi.encodeCall(MockTarget.setValue, (20))});

        vm.prank(agent);
        vm.expectRevert(); // ReputationTooLow: 50 < 70
        delegationManager.redeemDelegation(_asSingletonChain(tier2), action2);

        // -------------------------------------------------------------------
        // Step 4: Submit positive feedback to reach 70+
        // -------------------------------------------------------------------
        // Score is 50. Each positive adds 2. Need 10 positives to reach 70.
        for (uint256 i = 0; i < 10; i++) {
            reputationOracle.submitFeedback(agentId, true);
        }
        assertEq(reputationOracle.getReputationScore(agentId), 70, "Score should reach 70");

        // -------------------------------------------------------------------
        // Step 5: Agent can now use Tier 2 delegation
        // -------------------------------------------------------------------
        _redeemAsAgent(_asSingletonChain(tier2), action2);
        assertEq(target.value(), 20, "Tier 2 execution should succeed after reputation increase");
    }

    // =========================================================================
    //  test_multipleEnforcerComposition
    // =========================================================================

    /// @notice Tests that multiple enforcers compose correctly: SpendingCap + ContractWhitelist
    ///         + FunctionSelector. Each enforcer independently blocks invalid actions.
    function test_multipleEnforcerComposition() public {
        _registerAgent();
        userAccount = _createFundedAccount();

        // Build caveats: SpendingCap (5 ether/day) + ContractWhitelist + FunctionSelector.
        Caveat[] memory caveats = new Caveat[](3);

        // SpendingCap: 5 ether per day.
        caveats[0] = Caveat({enforcer: address(spendingCap), terms: abi.encode(uint256(5 ether), uint256(86400))});

        // ContractWhitelist: only MockTarget.
        address[] memory allowed = new address[](1);
        allowed[0] = address(target);
        caveats[1] = Caveat({enforcer: address(contractWhitelist), terms: abi.encode(allowed)});

        // FunctionSelector: only setValue(uint256).
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = MockTarget.setValue.selector;
        caveats[2] = Caveat({enforcer: address(functionSelector), terms: abi.encode(selectors)});

        Delegation memory delegation = Delegation({
            delegator: address(userAccount),
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 300,
            signature: ""
        });
        delegation = _signDelegation(delegation, userKey);
        Delegation[] memory chain = _asSingletonChain(delegation);

        // -------------------------------------------------------------------
        // 1. Correct target + correct selector + within cap -> passes
        // -------------------------------------------------------------------
        Action memory goodAction =
            Action({target: address(target), value: 1 ether, callData: abi.encodeCall(MockTarget.setValue, (42))});
        _redeemAsAgent(chain, goodAction);
        assertEq(target.value(), 42, "Good action should succeed");

        // -------------------------------------------------------------------
        // 2. Wrong target -> ContractWhitelistEnforcer blocks
        // -------------------------------------------------------------------
        MockTarget wrongTarget = new MockTarget();
        Action memory wrongTargetAction =
            Action({target: address(wrongTarget), value: 0, callData: abi.encodeCall(MockTarget.setValue, (99))});
        vm.prank(agent);
        vm.expectRevert(
            abi.encodeWithSelector(ContractWhitelistEnforcer.ContractNotWhitelisted.selector, address(wrongTarget))
        );
        delegationManager.redeemDelegation(chain, wrongTargetAction);

        // -------------------------------------------------------------------
        // 3. Wrong selector -> FunctionSelectorEnforcer blocks
        // -------------------------------------------------------------------
        bytes memory badCalldata = abi.encodeWithSignature("transfer(address,uint256)", address(this), 1);
        Action memory wrongSelectorAction = Action({target: address(target), value: 0, callData: badCalldata});
        vm.prank(agent);
        vm.expectRevert(); // SelectorNotAllowed
        delegationManager.redeemDelegation(chain, wrongSelectorAction);

        // -------------------------------------------------------------------
        // 4. Exceeding spending cap -> SpendingCapEnforcer blocks
        // -------------------------------------------------------------------
        // Already spent 1 ether. Cap is 5 ether/day. Trying 5 ether -> total 6 > 5.
        Action memory overCapAction =
            Action({target: address(target), value: 5 ether, callData: abi.encodeCall(MockTarget.setValue, (0))});
        vm.prank(agent);
        vm.expectRevert(); // SpendingCapExceeded
        delegationManager.redeemDelegation(chain, overCapAction);
    }
}
