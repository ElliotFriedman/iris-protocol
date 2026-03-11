// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisSafeModule} from "../src/compatibility/IrisSafeModule.sol";
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";

contract MockSafe {
    mapping(address => bool) public modules;
    bool public shouldSucceed = true;

    function enableModule(address module) external {
        modules[module] = true;
    }

    function isModuleEnabled(address module) external view returns (bool) {
        return modules[module];
    }

    function execTransactionFromModule(address to, uint256 value, bytes calldata data, uint8)
        external
        returns (bool)
    {
        if (!shouldSucceed) return false;
        (bool success,) = to.call{value: value}(data);
        return success;
    }

    function setShouldSucceed(bool v) external {
        shouldSucceed = v;
    }

    receive() external payable {}
}

contract MockCaveatEnforcer {
    uint256 public beforeHookCalls;
    uint256 public afterHookCalls;

    function beforeHook(
        bytes calldata,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external {
        beforeHookCalls++;
    }

    function afterHook(
        bytes calldata,
        bytes calldata,
        address,
        bytes32,
        address,
        address,
        address,
        uint256,
        bytes calldata
    ) external {
        afterHookCalls++;
    }
}

contract IrisSafeModuleTest is Test {
    IrisSafeModule module;
    MockSafe safe;
    MockCaveatEnforcer enforcer;

    address owner = makeAddr("owner");
    address delegationManager = makeAddr("delegationManager");
    address agent = makeAddr("agent");
    address other = makeAddr("other");

    // A simple target that receives calls
    address target = makeAddr("target");

    function setUp() public {
        module = new IrisSafeModule(delegationManager, owner);
        safe = new MockSafe();
        enforcer = new MockCaveatEnforcer();

        safe.enableModule(address(module));
    }

    function _buildDelegationWithCaveat() internal view returns (Delegation[] memory delegations, Action memory action) {
        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(enforcer), terms: ""});

        delegations = new Delegation[](1);
        delegations[0] = Delegation({
            delegator: owner,
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });

        action = Action({target: target, value: 0, callData: ""});
    }

    function _buildDelegationNoCaveat() internal view returns (Delegation[] memory delegations, Action memory action) {
        Caveat[] memory caveats = new Caveat[](0);

        delegations = new Delegation[](1);
        delegations[0] = Delegation({
            delegator: owner,
            delegate: agent,
            authority: address(0),
            caveats: caveats,
            salt: 1,
            signature: ""
        });

        action = Action({target: target, value: 0, callData: ""});
    }

    function test_redeemViaSafeSuccess() public {
        (Delegation[] memory delegations, Action memory action) = _buildDelegationNoCaveat();

        vm.prank(agent);
        module.redeemDelegationViaSafe(address(safe), delegations, action);
    }

    function test_redeemViaSafeCallsCaveats() public {
        (Delegation[] memory delegations, Action memory action) = _buildDelegationWithCaveat();

        vm.prank(agent);
        module.redeemDelegationViaSafe(address(safe), delegations, action);

        assertEq(enforcer.beforeHookCalls(), 1);
        assertEq(enforcer.afterHookCalls(), 1);
    }

    function test_redeemRevertsIfModuleNotEnabled() public {
        MockSafe unenabled = new MockSafe();
        (Delegation[] memory delegations, Action memory action) = _buildDelegationNoCaveat();

        vm.prank(agent);
        vm.expectRevert(abi.encodeWithSelector(IrisSafeModule.ModuleNotEnabled.selector, address(unenabled)));
        module.redeemDelegationViaSafe(address(unenabled), delegations, action);
    }

    function test_redeemRevertsOnEmptyChain() public {
        Delegation[] memory delegations = new Delegation[](0);
        Action memory action = Action({target: target, value: 0, callData: ""});

        vm.prank(agent);
        vm.expectRevert(IrisSafeModule.EmptyDelegationChain.selector);
        module.redeemDelegationViaSafe(address(safe), delegations, action);
    }

    function test_redeemRevertsOnSafeExecutionFailure() public {
        safe.setShouldSucceed(false);
        (Delegation[] memory delegations, Action memory action) = _buildDelegationNoCaveat();

        vm.prank(agent);
        vm.expectRevert(IrisSafeModule.SafeExecutionFailed.selector);
        module.redeemDelegationViaSafe(address(safe), delegations, action);
    }

    function test_transferOwnership() public {
        vm.prank(owner);
        module.transferOwnership(other);

        assertEq(module.owner(), other);
    }

    function test_transferOwnershipRevertsForNonOwner() public {
        vm.prank(other);
        vm.expectRevert(IrisSafeModule.NotOwner.selector);
        module.transferOwnership(other);
    }
}
