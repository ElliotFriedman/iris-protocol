// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount, PackedUserOperation} from "../src/IrisAccount.sol";
import {IrisAccountFactory} from "../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";

/// @title MockTarget
/// @notice A simple mock target contract for testing account execution.
contract MockTarget {
    uint256 public lastValue;
    bytes public lastData;

    function doSomething(uint256 x) external payable {
        lastValue = x;
        lastData = msg.data;
    }

    receive() external payable {}
}

/// @title IrisAccountTest
/// @notice Tests for IrisAccount and IrisAccountFactory.
contract IrisAccountTest is Test {
    IrisAccountFactory public factory;
    IrisDelegationManager public delegationManager;
    MockTarget public target;

    address owner;
    uint256 ownerKey;

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        delegationManager = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        target = new MockTarget();
    }

    // -------------------------------------------------------------------------
    // Factory: account creation
    // -------------------------------------------------------------------------

    function test_createAccount() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        assertTrue(account != address(0));
        assertTrue(account.code.length > 0);
    }

    function test_createAccountDeterministic() public {
        address predicted = factory.getAddress(owner, address(delegationManager), 0);
        address actual = factory.createAccount(owner, address(delegationManager), 0);
        assertEq(predicted, actual);
    }

    function test_createAccountIdempotent() public {
        address first = factory.createAccount(owner, address(delegationManager), 0);
        address second = factory.createAccount(owner, address(delegationManager), 0);
        assertEq(first, second);
    }

    function test_differentSaltsDifferentAddresses() public {
        address a1 = factory.createAccount(owner, address(delegationManager), 0);
        address a2 = factory.createAccount(owner, address(delegationManager), 1);
        assertTrue(a1 != a2);
    }

    // -------------------------------------------------------------------------
    // Owner operations
    // -------------------------------------------------------------------------

    function test_ownerCanExecute() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(account, 10 ether);

        vm.prank(owner);
        IrisAccount(payable(account)).execute(
            address(target), 1 ether, abi.encodeWithSignature("doSomething(uint256)", 42)
        );

        assertEq(target.lastValue(), 42);
        assertEq(address(target).balance, 1 ether);
    }

    function test_nonOwnerCannotExecute() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(IrisAccount.OnlyOwnerOrDelegationManager.selector);
        IrisAccount(payable(account)).execute(address(target), 0, "");
    }

    function test_ownerCanExecuteBatch() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(account, 10 ether);

        address[] memory targets = new address[](2);
        targets[0] = address(target);
        targets[1] = address(target);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSignature("doSomething(uint256)", 1);
        calldatas[1] = abi.encodeWithSignature("doSomething(uint256)", 2);

        vm.prank(owner);
        IrisAccount(payable(account)).executeBatch(targets, values, calldatas);

        assertEq(target.lastValue(), 2);
    }

    // -------------------------------------------------------------------------
    // Delegation management
    // -------------------------------------------------------------------------

    function test_isDelegationValidByDefault() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 hash = bytes32(uint256(99));
        assertTrue(IrisAccount(payable(account)).isDelegationValid(hash));
    }

    function test_ownerCanRevokeDelegation() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 hash = bytes32(uint256(99));

        vm.prank(owner);
        IrisAccount(payable(account)).revokeDelegation(hash);

        assertFalse(IrisAccount(payable(account)).isDelegationValid(hash));
    }

    function test_nonOwnerCannotRevokeDelegation() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(IrisAccount.OnlyOwner.selector);
        IrisAccount(payable(account)).revokeDelegation(bytes32(uint256(99)));
    }

    // -------------------------------------------------------------------------
    // Delegation manager access
    // -------------------------------------------------------------------------

    function test_delegationManagerCanExecute() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(account, 10 ether);

        vm.prank(address(delegationManager));
        IrisAccount(payable(account)).execute(
            address(target), 0, abi.encodeWithSignature("doSomething(uint256)", 7)
        );

        assertEq(target.lastValue(), 7);
    }

    function test_setDelegationManager() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        address newManager = makeAddr("newManager");

        vm.prank(owner);
        IrisAccount(payable(account)).setDelegationManager(newManager);

        assertEq(IrisAccount(payable(account)).delegationManager(), newManager);
    }

    // -------------------------------------------------------------------------
    // Signature validation (ERC-4337)
    // -------------------------------------------------------------------------

    function test_validateUserOp_validSignature() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 userOpHash = keccak256("test");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = account;
        userOp.signature = signature;

        vm.prank(address(uint160(0xE0A)));
        uint256 result = IrisAccount(payable(account)).validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 0);
    }

    function test_validateUserOp_invalidSignature() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 userOpHash = keccak256("test");

        // Sign with wrong key.
        (, uint256 wrongKey) = makeAddrAndKey("wrong");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = account;
        userOp.signature = signature;

        vm.prank(address(0xE0A));
        uint256 result = IrisAccount(payable(account)).validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 1);
    }

    // -------------------------------------------------------------------------
    // Receive ETH
    // -------------------------------------------------------------------------

    function test_accountCanReceiveETH() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(address(this), 1 ether);
        (bool ok,) = account.call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(account.balance, 1 ether);
    }
}
