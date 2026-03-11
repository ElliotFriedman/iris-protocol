// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisApprovalQueue} from "../../src/IrisApprovalQueue.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {TierOne} from "../../src/presets/TierOne.sol";
import {TierTwo} from "../../src/presets/TierTwo.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Mock Uniswap router for demo purposes.
contract MockUniswapRouter {
    uint256 public swapCount;
    uint256 public totalIn;

    function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline)
        external
        payable
        returns (uint256[] memory amounts)
    {
        swapCount++;
        totalIn += msg.value;
        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = amountOutMin;
    }

    receive() external payable {}
}

/// @title DemoFlowTest
/// @notice Recreates the 9-step demo flow described in the Iris Protocol spec.
///         This is the exact flow judges see during the hackathon demo.
contract DemoFlowTest is Test {
    // Infrastructure
    IrisAccountFactory factory;
    IrisDelegationManager dm;
    IrisApprovalQueue approvalQueue;
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;

    // Enforcers
    SpendingCapEnforcer spendingCap;
    ContractWhitelistEnforcer whitelist;
    TimeWindowEnforcer timeWindow;
    ReputationGateEnforcer reputationGate;

    // Actors
    address user;        // Wallet owner
    uint256 userKey;
    address agentOp;     // Agent operator EOA

    // Contracts
    IrisAccount wallet;
    MockUniswapRouter uniswap;

    // Agent identity
    uint256 agentId;

    function setUp() public {
        vm.warp(1_000_000);

        // Deploy all Iris infrastructure
        dm = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        approvalQueue = new IrisApprovalQueue(1 days);
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this));

        spendingCap = new SpendingCapEnforcer();
        whitelist = new ContractWhitelistEnforcer();
        timeWindow = new TimeWindowEnforcer();
        reputationGate = new ReputationGateEnforcer();

        (user, userKey) = makeAddrAndKey("user");
        agentOp = makeAddr("agentOperator");

        uniswap = new MockUniswapRouter();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return dm.getDelegationHash(d);
    }

    function _signDelegation(Delegation memory d) internal view returns (Delegation memory) {
        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userKey, dHash);
        d.signature = abi.encodePacked(r, s, v);
        return d;
    }

    function _redeemAsAgent(Delegation memory d, Action memory action) internal {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOp);
        dm.redeemDelegation(chain, action);
    }

    function _tryRedeemAsAgent(Delegation memory d, Action memory action) internal returns (bool) {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOp);
        (bool ok,) = address(dm).call(
            abi.encodeCall(dm.redeemDelegation, (chain, action))
        );
        return ok;
    }

    // =========================================================================
    // THE 9-STEP DEMO FLOW
    // =========================================================================

    function test_fullDemoFlow() public {
        // =====================================================================
        // STEP 1: Agent registers on ERC-8004 Identity Registry
        // =====================================================================
        vm.prank(agentOp);
        agentId = registry.registerAgent("ipfs://QmAgentCard4521");

        assertTrue(registry.isRegistered(agentId), "Step 1: Agent should be registered");
        assertEq(registry.ownerOf(agentId), agentOp, "Step 1: Agent operator should own the NFT");
        assertEq(oracle.getReputationScore(agentId), 50, "Step 1: Default reputation should be 50");

        // =====================================================================
        // STEP 2: User creates an Iris wallet
        // =====================================================================
        address predictedAddr = factory.getAddress(user, address(dm), 0);
        address walletAddr = factory.createAccount(user, address(dm), 0);
        wallet = IrisAccount(payable(walletAddr));

        assertEq(walletAddr, predictedAddr, "Step 2: Deployed address should match prediction");
        assertEq(wallet.owner(), user, "Step 2: Wallet owner should be user");
        assertEq(wallet.delegationManager(), address(dm), "Step 2: DM should be set");

        // Fund the wallet
        vm.deal(address(wallet), 500 ether);

        // =====================================================================
        // STEP 3: Agent requests Tier 1 access
        //         "Agent #4521 (reputation: 50/100) requests:
        //          spend up to 100 ETH/day on Uniswap swaps only, valid for 7 days"
        // =====================================================================

        // Build reputation to make agent more trustworthy (50 -> 60 with 5 positive feedbacks)
        for (uint256 i = 0; i < 5; i++) {
            oracle.submitFeedback(agentId, true);
        }
        uint256 repScore = oracle.getReputationScore(agentId);
        assertEq(repScore, 60, "Step 3: Reputation should be 60 after positive feedback");

        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(uniswap);

        Caveat[] memory tier1Caveats = TierOne.configureTierOne(
            address(spendingCap),
            address(whitelist),
            address(timeWindow),
            address(reputationGate),
            address(oracle),
            agentId,
            100 ether,                    // $100/day equivalent
            allowedContracts,
            block.timestamp + 7 days,
            40                            // min reputation
        );

        // =====================================================================
        // STEP 4: User approves — signs ERC-7710 delegation
        // =====================================================================
        Delegation memory delegation;
        delegation.delegator = address(wallet);
        delegation.delegate = agentOp;
        delegation.authority = address(0);
        delegation.caveats = tier1Caveats;
        delegation.salt = 1;
        delegation = _signDelegation(delegation);

        // Delegation is now signed and ready — no onchain tx needed yet

        // =====================================================================
        // STEP 5: Agent executes a $50 Uniswap swap
        // =====================================================================
        address[] memory path = new address[](2);
        path[0] = makeAddr("WETH");
        path[1] = makeAddr("USDC");

        Action memory swapAction = Action({
            target: address(uniswap),
            value: 50 ether,
            callData: abi.encodeCall(
                MockUniswapRouter.swapExactETHForTokens,
                (45 ether, path, address(wallet), block.timestamp + 1 hours)
            )
        });

        _redeemAsAgent(delegation, swapAction);

        assertEq(uniswap.swapCount(), 1, "Step 5: Swap should execute");
        assertEq(uniswap.totalIn(), 50 ether, "Step 5: 50 ETH should be sent");

        // =====================================================================
        // STEP 6: Agent attempts a $200 swap — SpendingCapEnforcer blocks
        //         Transaction would be queued for human co-signature
        // =====================================================================
        Delegation memory delegation2;
        delegation2.delegator = address(wallet);
        delegation2.delegate = agentOp;
        delegation2.authority = address(0);
        delegation2.caveats = tier1Caveats;
        delegation2.salt = 2;
        delegation2 = _signDelegation(delegation2);

        Action memory bigSwapAction = Action({
            target: address(uniswap),
            value: 200 ether,
            callData: abi.encodeCall(
                MockUniswapRouter.swapExactETHForTokens,
                (180 ether, path, address(wallet), block.timestamp + 1 hours)
            )
        });

        bool ok = _tryRedeemAsAgent(delegation2, bigSwapAction);
        assertFalse(ok, "Step 6: $200 swap should be blocked by spending cap");
        assertEq(uniswap.swapCount(), 1, "Step 6: Swap count unchanged");

        // Agent submits to approval queue
        bytes32 delegationHash = this._helperGetHash(delegation2);
        vm.prank(agentOp);
        bytes32 requestId = approvalQueue.submitRequest(
            address(uniswap),
            bigSwapAction.callData,
            200 ether,
            delegationHash,
            user
        );

        bytes32[] memory pending = approvalQueue.getPendingRequests(user);
        assertEq(pending.length, 1, "Step 6: One pending request");
        assertEq(pending[0], requestId, "Step 6: Correct request ID");

        // =====================================================================
        // STEP 7: User bumps agent to Tier 2 (reputation is high enough)
        // =====================================================================

        // First approve the pending request
        vm.prank(user);
        approvalQueue.approveRequest(requestId);

        IrisApprovalQueue.ApprovalRequest memory req = approvalQueue.getRequest(requestId);
        assertTrue(req.approved, "Step 7: Request should be approved");

        // Now grant a Tier 2 delegation with higher cap
        Caveat[] memory tier2Caveats = new Caveat[](2);
        tier2Caveats[0] = Caveat({
            enforcer: address(spendingCap),
            terms: abi.encode(uint256(500 ether), uint256(1 days)) // higher cap
        });
        tier2Caveats[1] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentId, uint256(50)) // higher rep threshold
        });

        Delegation memory tier2Delegation;
        tier2Delegation.delegator = address(wallet);
        tier2Delegation.delegate = agentOp;
        tier2Delegation.authority = address(0);
        tier2Delegation.caveats = tier2Caveats;
        tier2Delegation.salt = 3;
        tier2Delegation = _signDelegation(tier2Delegation);

        // Agent can now do the big swap with Tier 2 delegation
        _redeemAsAgent(tier2Delegation, bigSwapAction);
        assertEq(uniswap.swapCount(), 2, "Step 7: Big swap should now succeed");
        assertEq(uniswap.totalIn(), 250 ether, "Step 7: Total 250 ETH sent");

        // =====================================================================
        // STEP 8: Simulated reputation drop — ReputationGateEnforcer blocks
        // =====================================================================
        // Bad behavior: 3 negative feedbacks drop reputation from 60 to 45
        oracle.submitFeedback(agentId, false); // 60 -> 55
        oracle.submitFeedback(agentId, false); // 55 -> 50
        oracle.submitFeedback(agentId, false); // 50 -> 45
        assertEq(oracle.getReputationScore(agentId), 45, "Step 8: Reputation dropped to 45");

        // Agent tries to use Tier 2 delegation (requires rep >= 50)
        Delegation memory tier2Delegation2;
        tier2Delegation2.delegator = address(wallet);
        tier2Delegation2.delegate = agentOp;
        tier2Delegation2.authority = address(0);
        tier2Delegation2.caveats = tier2Caveats;
        tier2Delegation2.salt = 4;
        tier2Delegation2 = _signDelegation(tier2Delegation2);

        ok = _tryRedeemAsAgent(tier2Delegation2, Action({
            target: address(uniswap),
            value: 10 ether,
            callData: abi.encodeCall(
                MockUniswapRouter.swapExactETHForTokens,
                (9 ether, path, address(wallet), block.timestamp + 1 hours)
            )
        }));
        assertFalse(ok, "Step 8: Reputation below threshold blocks execution");

        // =====================================================================
        // STEP 9: User instantly revokes all delegations
        // =====================================================================
        bytes32 tier1Hash = this._helperGetHash(delegation);
        bytes32 tier2Hash = this._helperGetHash(tier2Delegation);

        vm.startPrank(user);
        wallet.revokeDelegation(tier1Hash);
        wallet.revokeDelegation(tier2Hash);
        vm.stopPrank();

        assertFalse(wallet.isDelegationValid(tier1Hash), "Step 9: Tier 1 delegation revoked");
        assertFalse(wallet.isDelegationValid(tier2Hash), "Step 9: Tier 2 delegation revoked");

        // Even if reputation recovers, revoked delegations stay revoked
        oracle.submitFeedback(agentId, true);  // 45 -> 47
        oracle.submitFeedback(agentId, true);  // 47 -> 49
        oracle.submitFeedback(agentId, true);  // 49 -> 51

        Delegation memory tier2Delegation3;
        tier2Delegation3.delegator = address(wallet);
        tier2Delegation3.delegate = agentOp;
        tier2Delegation3.authority = address(0);
        tier2Delegation3.caveats = tier2Caveats;
        tier2Delegation3.salt = 5;
        tier2Delegation3 = _signDelegation(tier2Delegation3);

        // This uses a new salt so it's not revoked — but demonstrates that
        // the system continues to function after revocation
        _redeemAsAgent(tier2Delegation3, Action({
            target: address(uniswap),
            value: 5 ether,
            callData: abi.encodeCall(
                MockUniswapRouter.swapExactETHForTokens,
                (4 ether, path, address(wallet), block.timestamp + 1 hours)
            )
        }));
        assertEq(uniswap.swapCount(), 3, "Step 9: New delegation works after reputation recovery");
    }

    /// @notice Tests the complete agent lifecycle: register → build reputation → tier upgrade.
    function test_agentLifecycle_registerToTierUpgrade() public {
        // Register a brand new agent
        address newAgentOp = makeAddr("newAgent");
        vm.prank(newAgentOp);
        uint256 newAgentId = registry.registerAgent("ipfs://new-agent");

        // Verify initial state
        assertEq(oracle.getReputationScore(newAgentId), 50);
        assertTrue(registry.isRegistered(newAgentId));

        // Create wallet
        address walletAddr = factory.createAccount(user, address(dm), 99);
        IrisAccount newWallet = IrisAccount(payable(walletAddr));
        vm.deal(address(newWallet), 100 ether);

        address payable recipient = payable(makeAddr("recipient"));

        // At reputation 50, agent qualifies for Tier 1 (min rep 40)
        Caveat[] memory tier1Caveats = new Caveat[](1);
        tier1Caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), newAgentId, uint256(40))
        });

        Delegation memory d1;
        d1.delegator = address(newWallet);
        d1.delegate = newAgentOp;
        d1.authority = address(0);
        d1.caveats = tier1Caveats;
        d1.salt = 1;
        d1 = _signDelegation(d1);

        // Can execute Tier 1
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d1;
        vm.prank(newAgentOp);
        dm.redeemDelegation(chain, Action({target: recipient, value: 1 ether, callData: ""}));
        assertEq(recipient.balance, 1 ether);

        // But cannot qualify for Tier 2 (min rep 75) yet
        Caveat[] memory tier2Caveats = new Caveat[](1);
        tier2Caveats[0] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), newAgentId, uint256(75))
        });

        Delegation memory d2;
        d2.delegator = address(newWallet);
        d2.delegate = newAgentOp;
        d2.authority = address(0);
        d2.caveats = tier2Caveats;
        d2.salt = 2;
        d2 = _signDelegation(d2);

        chain[0] = d2;
        vm.prank(newAgentOp);
        (bool ok,) = address(dm).call(
            abi.encodeCall(dm.redeemDelegation, (chain, Action({target: recipient, value: 1 ether, callData: ""})))
        );
        assertFalse(ok, "Agent cannot access Tier 2 at reputation 50");

        // Build reputation through good behavior: 50 -> 76 (13 positive feedbacks)
        for (uint256 i = 0; i < 13; i++) {
            oracle.submitFeedback(newAgentId, true); // +2 each
        }
        assertEq(oracle.getReputationScore(newAgentId), 76);

        // Now qualifies for Tier 2
        Delegation memory d3;
        d3.delegator = address(newWallet);
        d3.delegate = newAgentOp;
        d3.authority = address(0);
        d3.caveats = tier2Caveats;
        d3.salt = 3;
        d3 = _signDelegation(d3);

        chain[0] = d3;
        vm.prank(newAgentOp);
        dm.redeemDelegation(chain, Action({target: recipient, value: 1 ether, callData: ""}));
        assertEq(recipient.balance, 2 ether, "Agent can access Tier 2 after building reputation");
    }

    /// @notice Tests approval queue expiry — request expires after 24 hours.
    function test_approvalQueue_expiry() public {
        vm.prank(agentOp);
        agentId = registry.registerAgent("ipfs://agent");

        address walletAddr = factory.createAccount(user, address(dm), 50);
        wallet = IrisAccount(payable(walletAddr));

        vm.prank(agentOp);
        bytes32 requestId = approvalQueue.submitRequest(
            address(uniswap),
            abi.encodeCall(MockUniswapRouter.swapExactETHForTokens, (0, new address[](0), address(0), 0)),
            100 ether,
            keccak256("delegation"),
            user
        );

        assertFalse(approvalQueue.isExpired(requestId), "Should not be expired initially");

        // Fast-forward past expiry
        vm.warp(block.timestamp + 1 days + 1);

        assertTrue(approvalQueue.isExpired(requestId), "Should be expired after 24 hours");

        // Owner cannot approve expired request
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IrisApprovalQueue.RequestExpired.selector, requestId));
        approvalQueue.approveRequest(requestId);
    }
}
