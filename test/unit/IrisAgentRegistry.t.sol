// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";

contract IrisAgentRegistryTest is Test {
    IrisAgentRegistry registry;
    address operator;
    address stranger;

    event AgentRegistered(uint256 indexed agentId, address indexed operator, string metadataURI);
    event AgentDeactivated(uint256 indexed agentId, address indexed operator);

    function setUp() public {
        registry = new IrisAgentRegistry();
        operator = makeAddr("operator");
        stranger = makeAddr("stranger");
    }

    // -----------------------------------------------------------------------
    // registerAgent
    // -----------------------------------------------------------------------

    function test_registerAgent_assignsIncrementingIds() public {
        vm.prank(operator);
        uint256 id1 = registry.registerAgent("ipfs://a");
        assertEq(id1, 1);

        vm.prank(operator);
        uint256 id2 = registry.registerAgent("ipfs://b");
        assertEq(id2, 2);
    }

    function test_registerAgent_setsMetadata() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://meta");

        IrisAgentRegistry.AgentInfo memory info = registry.getAgent(id);
        assertEq(info.operator, operator);
        assertEq(info.metadataURI, "ipfs://meta");
        assertTrue(info.active);
        assertEq(info.registeredAt, block.timestamp);
    }

    function test_registerAgent_emitsEvent() public {
        vm.prank(operator);
        vm.expectEmit(true, true, false, true);
        emit AgentRegistered(1, operator, "ipfs://agent");
        registry.registerAgent("ipfs://agent");
    }

    function test_registerAgent_mintsNFT() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");

        assertEq(registry.ownerOf(id), operator);
    }

    // -----------------------------------------------------------------------
    // deactivateAgent
    // -----------------------------------------------------------------------

    function test_deactivateAgent_setsInactive() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");

        vm.prank(operator);
        vm.expectEmit(true, true, false, false);
        emit AgentDeactivated(id, operator);
        registry.deactivateAgent(id);

        assertFalse(registry.isRegistered(id));
    }

    function test_deactivateAgent_revertsForStranger() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");

        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.NotOperator.selector, id, stranger));
        registry.deactivateAgent(id);
    }

    function test_deactivateAgent_revertsForNonExistent() public {
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentNotFound.selector, 999));
        registry.deactivateAgent(999);
    }

    function test_deactivateAgent_revertsIfAlreadyInactive() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");

        vm.prank(operator);
        registry.deactivateAgent(id);

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentAlreadyInactive.selector, id));
        registry.deactivateAgent(id);
    }

    // -----------------------------------------------------------------------
    // Views
    // -----------------------------------------------------------------------

    function test_isRegistered_trueForActive() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");
        assertTrue(registry.isRegistered(id));
    }

    function test_isRegistered_falseForInactive() public {
        vm.prank(operator);
        uint256 id = registry.registerAgent("ipfs://x");
        vm.prank(operator);
        registry.deactivateAgent(id);
        assertFalse(registry.isRegistered(id));
    }

    function test_isRegistered_falseForNonExistent() public view {
        assertFalse(registry.isRegistered(999));
    }

    function test_getAgent_revertsForNonExistent() public {
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentNotFound.selector, 999));
        registry.getAgent(999);
    }

    function test_ownerOf_revertsForNonExistent() public {
        vm.expectRevert(abi.encodeWithSelector(IrisAgentRegistry.AgentNotFound.selector, 999));
        registry.ownerOf(999);
    }
}
