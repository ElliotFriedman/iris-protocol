// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {FunctionSelectorEnforcer} from "../../src/caveats/FunctionSelectorEnforcer.sol";

contract FunctionSelectorEnforcerTest is Test {
    FunctionSelectorEnforcer enforcer;

    bytes4 constant TRANSFER_SEL = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 constant APPROVE_SEL = bytes4(keccak256("approve(address,uint256)"));
    bytes4 constant BURN_SEL = bytes4(keccak256("burn(uint256)"));

    function setUp() public {
        enforcer = new FunctionSelectorEnforcer();
    }

    function _terms(bytes4[] memory selectors) internal pure returns (bytes memory) {
        return abi.encode(selectors);
    }

    function _callBefore(bytes memory terms, bytes memory callData) internal view {
        enforcer.beforeHook(terms, "", address(0), bytes32(0), address(0), address(0), address(0), 0, callData);
    }

    // -----------------------------------------------------------------------
    // Tests
    // -----------------------------------------------------------------------

    function test_beforeHook_allowsWhitelistedSelector() public view {
        bytes4[] memory sels = new bytes4[](2);
        sels[0] = TRANSFER_SEL;
        sels[1] = APPROVE_SEL;

        _callBefore(_terms(sels), abi.encodeWithSelector(TRANSFER_SEL, address(1), uint256(100)));
    }

    function test_beforeHook_revertsForDisallowedSelector() public {
        bytes4[] memory sels = new bytes4[](1);
        sels[0] = TRANSFER_SEL;

        vm.expectRevert(
            abi.encodeWithSelector(FunctionSelectorEnforcer.SelectorNotAllowed.selector, BURN_SEL)
        );
        _callBefore(_terms(sels), abi.encodeWithSelector(BURN_SEL, uint256(100)));
    }

    function test_beforeHook_revertsWithEmptyList() public {
        bytes4[] memory sels = new bytes4[](0);

        vm.expectRevert(
            abi.encodeWithSelector(FunctionSelectorEnforcer.SelectorNotAllowed.selector, TRANSFER_SEL)
        );
        _callBefore(_terms(sels), abi.encodeWithSelector(TRANSFER_SEL, address(1), uint256(100)));
    }

    function test_beforeHook_matchesSecondSelector() public view {
        bytes4[] memory sels = new bytes4[](2);
        sels[0] = TRANSFER_SEL;
        sels[1] = APPROVE_SEL;

        _callBefore(_terms(sels), abi.encodeWithSelector(APPROVE_SEL, address(1), uint256(100)));
    }

    function test_afterHook_isNoop() public {
        FunctionSelectorEnforcer e = new FunctionSelectorEnforcer();
        e.afterHook("", "", address(0), bytes32(0), address(0), address(0), address(0), 0, "");
    }
}
