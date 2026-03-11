// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test} from "forge-std/Test.sol";
import {FunctionSelectorEnforcer} from "../src/caveats/FunctionSelectorEnforcer.sol";

contract FunctionSelectorEnforcerTest is Test {
    FunctionSelectorEnforcer enforcer;

    address constant DM = address(0x1);
    bytes32 constant HASH = bytes32(uint256(1));
    address constant DELEGATOR = address(0x2);
    address constant REDEEMER = address(0x3);
    address constant TARGET = address(0x4);

    function setUp() public {
        enforcer = new FunctionSelectorEnforcer();
    }

    function _beforeHook(bytes memory terms, bytes memory callData) internal view {
        enforcer.beforeHook(terms, "", DM, HASH, DELEGATOR, REDEEMER, TARGET, 0, callData);
    }

    function test_allowsWhitelistedSelector() public view {
        bytes4 sel = bytes4(keccak256("transfer(address,uint256)"));
        bytes4[] memory allowed = new bytes4[](1);
        allowed[0] = sel;
        bytes memory callData = abi.encodeWithSelector(sel, address(0x5), 100);
        _beforeHook(abi.encode(allowed), callData);
    }

    function test_allowsAnyOfMultipleSelectors() public view {
        bytes4 sel1 = bytes4(keccak256("transfer(address,uint256)"));
        bytes4 sel2 = bytes4(keccak256("approve(address,uint256)"));
        bytes4 sel3 = bytes4(keccak256("mint(address,uint256)"));

        bytes4[] memory allowed = new bytes4[](3);
        allowed[0] = sel1;
        allowed[1] = sel2;
        allowed[2] = sel3;
        bytes memory terms = abi.encode(allowed);

        _beforeHook(terms, abi.encodeWithSelector(sel1, address(0x5), 100));
        _beforeHook(terms, abi.encodeWithSelector(sel2, address(0x5), 100));
        _beforeHook(terms, abi.encodeWithSelector(sel3, address(0x5), 100));
    }

    function test_revertsForDisallowedSelector() public {
        bytes4 allowedSel = bytes4(keccak256("transfer(address,uint256)"));
        bytes4 badSel = bytes4(keccak256("burn(uint256)"));

        bytes4[] memory allowed = new bytes4[](1);
        allowed[0] = allowedSel;

        vm.expectRevert(
            abi.encodeWithSelector(FunctionSelectorEnforcer.SelectorNotAllowed.selector, badSel)
        );
        _beforeHook(abi.encode(allowed), abi.encodeWithSelector(badSel, 100));
    }
}
