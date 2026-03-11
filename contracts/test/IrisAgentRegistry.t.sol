// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAgentRegistry} from "../src/identity/IrisAgentRegistry.sol";

contract IrisAgentRegistryTest is Test {
    IrisAgentRegistry registry;
    address operator = makeAddr("operator");
    address other = makeAddr("other");

    function setUp() public {
        registry = new IrisAgentRegistry();
    }

    function test_registerAgent() public {
        vm.prank(operator);
        uint256 agentId = registry.registerAgent("ipfs://metadata");

        assertEq(agentId, 1);

        IrisAgentRegistry.AgentInfo memory info = registry.getAgent(agentId);
        assertEq(info.operator, operator);
        assertEq(info.metadataURI, "ipfs://metadata");
        assertTrue(info.active);
        assertEq(info.registeredAt, block.timestamp);
    }

    function test_registerMultipleAgents() public {
        vm.prank(operator);
        uint256 id1 = registry.registerAgent("ipfs://agent1");

        vm.prank(other);
        uint256 id2 = registry.registerAgent("ipfs://agent2");

        assertEq(id1, 1);
        assertEq(id2, 2);
    }

    function test_deactivateAgent() public {
        vm.prank(operator);
        uint256 agentId = registry.registerAgent("ipfs://metadata");

        assertTrue(registry.isRegistered(agentId));

        vm.prank(operator);
        registry.deactivateAgent(agentId);

        assertFalse(registry.isRegistered(agentId));
    }

    function test_deactivateRevertsForNonOperator() public {
        vm.prank(operator);
        uint256 agentId = registry.registerAgent("ipfs://metadata");

        vm.prank(other);
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.NotOperator.selector, agentId, other));
        registry.deactivateAgent(agentId);
    }

    function test_deactivateRevertsIfAlreadyInactive() public {
        vm.prank(operator);
        uint256 agentId = registry.registerAgent("ipfs://metadata");

        vm.prank(operator);
        registry.deactivateAgent(agentId);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentAlreadyInactive.selector, agentId));
        registry.deactivateAgent(agentId);
    }

    function test_getAgentRevertsForNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentNotFound.selector, 999));
        registry.getAgent(999);
    }

    function test_ownerOf() public {
        vm.prank(operator);
        uint256 agentId = registry.registerAgent("ipfs://metadata");

        assertEq(registry.ownerOf(agentId), operator);
    }

    function test_ownerOfRevertsForNonexistent() public {
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentNotFound.selector, 999));
        registry.ownerOf(999);
    }

    function test_isRegisteredReturnsFalseForNonexistent() public view {
        assertFalse(registry.isRegistered(999));
    }
}
