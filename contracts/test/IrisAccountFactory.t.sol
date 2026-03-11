// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisAccount} from "../src/IrisAccount.sol";

contract IrisAccountFactoryTest is Test {
    IrisAccountFactory factory;

    address owner = makeAddr("owner");
    address delegationMgr = makeAddr("delegationManager");

    function setUp() public {
        factory = new IrisAccountFactory();
    }

    function test_createAccountDeploysCorrectly() public {
        address account = factory.createAccount(owner, delegationMgr, 1);
        assertTrue(account != address(0));
        assertTrue(account.code.length > 0);

        IrisAccount iris = IrisAccount(payable(account));
        assertEq(iris.owner(), owner);
        assertEq(iris.delegationManager(), delegationMgr);
    }

    function test_getAddressMatchesDeployedAddress() public {
        address predicted = factory.getAddress(owner, delegationMgr, 1);
        address deployed = factory.createAccount(owner, delegationMgr, 1);
        assertEq(predicted, deployed);
    }

    function test_createAccountReturnsSameAddressIfExists() public {
        address first = factory.createAccount(owner, delegationMgr, 1);
        address second = factory.createAccount(owner, delegationMgr, 1);
        assertEq(first, second);
    }

    function test_differentSaltsProduceDifferentAddresses() public {
        address a = factory.createAccount(owner, delegationMgr, 1);
        address b = factory.createAccount(owner, delegationMgr, 2);
        assertTrue(a != b);
    }
}
