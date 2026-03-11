// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisDeployer} from "../src/deployers/IrisDeployer.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @title IrisDeployer Tests
/// @notice Direct tests for the IrisDeployer library functions and MockERC20 coverage.
contract IrisDeployerTest is Test {
    // =========================================================================
    // deployAll
    // =========================================================================

    function test_deployAll() public {
        IrisDeployer.Deployment memory dep = IrisDeployer.deployAll(address(this), 3600);

        // Every contract address must be non-zero
        assertTrue(address(dep.delegationManager) != address(0), "delegationManager");
        assertTrue(address(dep.factory) != address(0), "factory");
        assertTrue(address(dep.agentRegistry) != address(0), "agentRegistry");
        assertTrue(address(dep.reputationOracle) != address(0), "reputationOracle");
        assertTrue(address(dep.spendingCap) != address(0), "spendingCap");
        assertTrue(address(dep.contractWhitelist) != address(0), "contractWhitelist");
        assertTrue(address(dep.functionSelector) != address(0), "functionSelector");
        assertTrue(address(dep.timeWindow) != address(0), "timeWindow");
        assertTrue(address(dep.singleTxCap) != address(0), "singleTxCap");
        assertTrue(address(dep.cooldown) != address(0), "cooldown");
        assertTrue(address(dep.reputationGate) != address(0), "reputationGate");
        assertTrue(address(dep.approvalQueue) != address(0), "approvalQueue");
    }

    // =========================================================================
    // deployCore — delegates to deployAll with default 86400 expiry
    // =========================================================================

    function test_deployCore() public {
        IrisDeployer.Deployment memory dep = IrisDeployer.deployCore(address(this));

        // All contracts deployed, same as deployAll
        assertTrue(address(dep.delegationManager) != address(0), "delegationManager");
        assertTrue(address(dep.factory) != address(0), "factory");
        assertTrue(address(dep.agentRegistry) != address(0), "agentRegistry");
        assertTrue(address(dep.reputationOracle) != address(0), "reputationOracle");
        assertTrue(address(dep.spendingCap) != address(0), "spendingCap");
        assertTrue(address(dep.contractWhitelist) != address(0), "contractWhitelist");
        assertTrue(address(dep.functionSelector) != address(0), "functionSelector");
        assertTrue(address(dep.timeWindow) != address(0), "timeWindow");
        assertTrue(address(dep.singleTxCap) != address(0), "singleTxCap");
        assertTrue(address(dep.cooldown) != address(0), "cooldown");
        assertTrue(address(dep.reputationGate) != address(0), "reputationGate");
        assertTrue(address(dep.approvalQueue) != address(0), "approvalQueue");
    }

    // =========================================================================
    // deployAll with custom expiry
    // =========================================================================

    function test_deployAllWithCustomExpiry() public {
        uint256 customExpiry = 7200; // 2 hours
        IrisDeployer.Deployment memory dep = IrisDeployer.deployAll(address(this), customExpiry);

        // Approval queue deployed with custom expiry
        assertTrue(address(dep.approvalQueue) != address(0), "approvalQueue exists");
        assertEq(dep.approvalQueue.expiryDuration(), customExpiry, "custom expiry set");
    }

    // =========================================================================
    // Deployed contracts are usable
    // =========================================================================

    function test_deployedContractsAreUsable() public {
        IrisDeployer.Deployment memory dep = IrisDeployer.deployAll(address(this), 86_400);

        // Agent registry: register an agent and verify
        uint256 agentId = dep.agentRegistry.registerAgent("ipfs://test");
        assertTrue(dep.agentRegistry.isRegistered(agentId), "agent registered");

        // Reputation oracle: submit feedback
        dep.reputationOracle.submitFeedback(agentId, true);
        assertGt(dep.reputationOracle.getReputationScore(agentId), 0, "reputation increased");

        // Account factory: predict address
        address predicted = dep.factory.getAddress(address(this), address(dep.delegationManager), 0);
        assertTrue(predicted != address(0), "predicted address non-zero");

        // Approval queue: expiry is correct
        assertEq(dep.approvalQueue.expiryDuration(), 86_400, "default expiry");
    }

    // =========================================================================
    // Each deployment produces unique contract instances
    // =========================================================================

    function test_deploymentsAreIndependent() public {
        IrisDeployer.Deployment memory d1 = IrisDeployer.deployAll(address(this), 86_400);
        IrisDeployer.Deployment memory d2 = IrisDeployer.deployAll(address(this), 86_400);

        // Different deployments should yield different addresses
        assertTrue(address(d1.delegationManager) != address(d2.delegationManager), "independent managers");
        assertTrue(address(d1.factory) != address(d2.factory), "independent factories");
        assertTrue(address(d1.approvalQueue) != address(d2.approvalQueue), "independent queues");
    }
}

/// @title MockERC20 Coverage Tests
/// @notice Covers transfer, approve, transferFrom branches for the project MockERC20.
contract MockERC20Test is Test {
    MockERC20 token;
    address alice;
    address bob;

    function setUp() public {
        token = new MockERC20("Test Token", "TT");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        token.mint(alice, 1000 ether);
    }

    function test_nameAndSymbol() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TT");
        assertEq(token.decimals(), 18);
    }

    function test_mint() public {
        uint256 supplyBefore = token.totalSupply();
        token.mint(bob, 500 ether);
        assertEq(token.balanceOf(bob), 500 ether);
        assertEq(token.totalSupply(), supplyBefore + 500 ether);
    }

    function test_transfer() public {
        vm.prank(alice);
        bool ok = token.transfer(bob, 100 ether);
        assertTrue(ok);
        assertEq(token.balanceOf(bob), 100 ether);
        assertEq(token.balanceOf(alice), 900 ether);
    }

    function test_transferInsufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert("ERC20: insufficient balance");
        token.transfer(bob, 2000 ether);
    }

    function test_approve() public {
        vm.prank(alice);
        bool ok = token.approve(bob, 500 ether);
        assertTrue(ok);
        assertEq(token.allowance(alice, bob), 500 ether);
    }

    function test_transferFrom() public {
        vm.prank(alice);
        token.approve(bob, 300 ether);

        vm.prank(bob);
        bool ok = token.transferFrom(alice, bob, 200 ether);
        assertTrue(ok);
        assertEq(token.balanceOf(bob), 200 ether);
        assertEq(token.allowance(alice, bob), 100 ether);
    }

    function test_transferFromInsufficientAllowance() public {
        vm.prank(alice);
        token.approve(bob, 50 ether);

        vm.prank(bob);
        vm.expectRevert("ERC20: insufficient allowance");
        token.transferFrom(alice, bob, 100 ether);
    }

    function test_transferFromMaxAllowance() public {
        vm.prank(alice);
        token.approve(bob, type(uint256).max);

        vm.prank(bob);
        token.transferFrom(alice, bob, 100 ether);

        // Max allowance should not decrease
        assertEq(token.allowance(alice, bob), type(uint256).max);
        assertEq(token.balanceOf(bob), 100 ether);
    }
}
