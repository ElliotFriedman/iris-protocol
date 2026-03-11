// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";

contract IrisAccountFactoryTest is Test {
    IrisAccountFactory factory;
    address owner;
    address delegationManager;

    event AccountCreated(address indexed account, address indexed owner);

    function setUp() public {
        factory = new IrisAccountFactory();
        owner = makeAddr("owner");
        delegationManager = makeAddr("delegationManager");
    }

    // -----------------------------------------------------------------------
    // createAccount
    // -----------------------------------------------------------------------

    function test_createAccount_deploysAtPredictedAddress() public {
        address predicted = factory.getAddress(owner, delegationManager, 42);

        vm.expectEmit(true, true, false, false);
        emit AccountCreated(predicted, owner);
        address actual = factory.createAccount(owner, delegationManager, 42);

        assertEq(actual, predicted);
        assertGt(actual.code.length, 0);
    }

    function test_createAccount_setsOwnerAndManager() public {
        address acct = factory.createAccount(owner, delegationManager, 1);
        IrisAccount account = IrisAccount(payable(acct));

        assertEq(account.owner(), owner);
        assertEq(account.delegationManager(), delegationManager);
    }

    function test_createAccount_returnsSameAddressIfAlreadyDeployed() public {
        address first = factory.createAccount(owner, delegationManager, 1);
        address second = factory.createAccount(owner, delegationManager, 1);
        assertEq(first, second);
    }

    function test_createAccount_differentSaltsGiveDifferentAddresses() public {
        address a1 = factory.createAccount(owner, delegationManager, 1);
        address a2 = factory.createAccount(owner, delegationManager, 2);
        assertTrue(a1 != a2);
    }

    function test_createAccount_differentOwnersGiveDifferentAddresses() public {
        address owner2 = makeAddr("owner2");
        address a1 = factory.createAccount(owner, delegationManager, 1);
        address a2 = factory.createAccount(owner2, delegationManager, 1);
        assertTrue(a1 != a2);
    }

    // -----------------------------------------------------------------------
    // getAddress
    // -----------------------------------------------------------------------

    function test_getAddress_deterministicPrediction() public view {
        address p1 = factory.getAddress(owner, delegationManager, 1);
        address p2 = factory.getAddress(owner, delegationManager, 1);
        assertEq(p1, p2);
    }

    function test_getAddress_differentInputsDifferentPrediction() public view {
        address p1 = factory.getAddress(owner, delegationManager, 1);
        address p2 = factory.getAddress(owner, delegationManager, 2);
        assertTrue(p1 != p2);
    }
}
