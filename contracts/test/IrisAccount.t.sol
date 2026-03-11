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

/// @title RevertingTarget
/// @notice A mock that always reverts, used to test execution failure paths.
contract RevertingTarget {
    error AlwaysReverts();

    function doRevert() external pure {
        revert AlwaysReverts();
    }

    fallback() external payable {
        revert AlwaysReverts();
    }
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

        // Must be called by the canonical ERC-4337 v0.7 EntryPoint.
        address entryPoint = IrisAccount(payable(account)).ENTRY_POINT();
        vm.prank(entryPoint);
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

        address entryPoint = IrisAccount(payable(account)).ENTRY_POINT();
        vm.prank(entryPoint);
        uint256 result = IrisAccount(payable(account)).validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 1);
    }

    function test_validateUserOp_rejectsNonEntryPoint() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);

        PackedUserOperation memory userOp;
        userOp.sender = account;
        userOp.signature = new bytes(65);

        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert(IrisAccount.OnlyEntryPoint.selector);
        IrisAccount(payable(account)).validateUserOp(userOp, keccak256("test"), 0);
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

    // -------------------------------------------------------------------------
    // Execution failure paths
    // -------------------------------------------------------------------------

    function test_executeRevertsOnCallFailure() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        RevertingTarget reverter = new RevertingTarget();

        vm.prank(owner);
        vm.expectRevert(IrisAccount.ExecutionFailed.selector);
        IrisAccount(payable(account)).execute(
            address(reverter), 0, abi.encodeWithSignature("doRevert()")
        );
    }

    function test_executeBatchRevertsOnCallFailure() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        RevertingTarget reverter = new RevertingTarget();

        address[] memory targets = new address[](2);
        targets[0] = address(target);
        targets[1] = address(reverter);

        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;

        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encodeWithSignature("doSomething(uint256)", 1);
        calldatas[1] = abi.encodeWithSignature("doRevert()");

        vm.prank(owner);
        vm.expectRevert(IrisAccount.ExecutionFailed.selector);
        IrisAccount(payable(account)).executeBatch(targets, values, calldatas);
    }

    function test_executeBatchEmpty() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);

        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);

        vm.prank(owner);
        bytes[] memory results = IrisAccount(payable(account)).executeBatch(targets, values, calldatas);
        assertEq(results.length, 0);
    }

    function test_executeBatchLengthMismatchReverts() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);

        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](2);

        vm.prank(owner);
        vm.expectRevert("Length mismatch");
        IrisAccount(payable(account)).executeBatch(targets, values, calldatas);
    }

    // -------------------------------------------------------------------------
    // validateUserOp: missingAccountFunds path
    // -------------------------------------------------------------------------

    function test_validateUserOp_validSignatureWithFunds() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(account, 10 ether);

        bytes32 userOpHash = keccak256("test");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = account;
        userOp.signature = signature;

        address entryPoint = IrisAccount(payable(account)).ENTRY_POINT();
        uint256 entryPointBalBefore = entryPoint.balance;

        vm.prank(entryPoint);
        uint256 result = IrisAccount(payable(account)).validateUserOp(userOp, userOpHash, 1 ether);
        assertEq(result, 0);
        assertEq(entryPoint.balance, entryPointBalBefore + 1 ether);
    }

    function test_validateUserOp_invalidSignatureReturnsOne() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 userOpHash = keccak256("test2");

        (, uint256 wrongKey) = makeAddrAndKey("wrongKey2");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wrongKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = account;
        userOp.signature = signature;

        address entryPoint = IrisAccount(payable(account)).ENTRY_POINT();
        vm.prank(entryPoint);
        uint256 result = IrisAccount(payable(account)).validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 1);
    }

    // -------------------------------------------------------------------------
    // Delegation: revocation then validity check
    // -------------------------------------------------------------------------

    function test_isDelegationValidReturnsFalseAfterRevocation() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        bytes32 hash = bytes32(uint256(42));

        // Valid before revocation.
        assertTrue(IrisAccount(payable(account)).isDelegationValid(hash));

        vm.prank(owner);
        IrisAccount(payable(account)).revokeDelegation(hash);

        // Invalid after revocation.
        assertFalse(IrisAccount(payable(account)).isDelegationValid(hash));
    }

    // -------------------------------------------------------------------------
    // setDelegationManager: non-owner revert
    // -------------------------------------------------------------------------

    function test_setDelegationManagerRevertsForNonOwner() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        address attacker = makeAddr("attacker");

        vm.prank(attacker);
        vm.expectRevert(IrisAccount.OnlyOwner.selector);
        IrisAccount(payable(account)).setDelegationManager(address(0));
    }

    // -------------------------------------------------------------------------
    // Factory: different owners, getAddress consistency
    // -------------------------------------------------------------------------

    function test_factoryCreatesAccountWithDifferentOwners() public {
        address owner2 = makeAddr("owner2");
        address a1 = factory.createAccount(owner, address(delegationManager), 0);
        address a2 = factory.createAccount(owner2, address(delegationManager), 0);
        assertTrue(a1 != a2);
        assertEq(IrisAccount(payable(a1)).owner(), owner);
        assertEq(IrisAccount(payable(a2)).owner(), owner2);
    }

    function test_factoryGetAddressConsistency() public {
        // Predict address before deployment.
        address predicted = factory.getAddress(owner, address(delegationManager), 7);
        assertTrue(predicted != address(0));

        // Deploy and verify match.
        address actual = factory.createAccount(owner, address(delegationManager), 7);
        assertEq(predicted, actual);

        // getAddress still returns the same value after deployment.
        address postDeploy = factory.getAddress(owner, address(delegationManager), 7);
        assertEq(predicted, postDeploy);
    }

    function test_factoryCreateAccountReturnsExistingWithoutEvent() public {
        // First creation emits event.
        vm.expectEmit(true, true, false, false);
        emit IrisAccountFactory.AccountCreated(
            factory.getAddress(owner, address(delegationManager), 0), owner
        );
        address first = factory.createAccount(owner, address(delegationManager), 0);

        // Second call returns the same address without reverting.
        address second = factory.createAccount(owner, address(delegationManager), 0);
        assertEq(first, second);
    }

    // -------------------------------------------------------------------------
    // Receive ETH via direct transfer (additional)
    // -------------------------------------------------------------------------

    function test_receiveETHViaTransfer() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        vm.deal(address(this), 2 ether);

        // Send ETH with empty calldata to hit receive().
        (bool ok,) = payable(account).call{value: 0.5 ether}("");
        assertTrue(ok);
        assertEq(account.balance, 0.5 ether);
    }

    // -------------------------------------------------------------------------
    // executeBatch: non-owner revert
    // -------------------------------------------------------------------------

    function test_executeBatchRevertsForNonOwner() public {
        address account = factory.createAccount(owner, address(delegationManager), 0);
        address attacker = makeAddr("attacker");

        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory calldatas = new bytes[](1);

        vm.prank(attacker);
        vm.expectRevert(IrisAccount.OnlyOwnerOrDelegationManager.selector);
        IrisAccount(payable(account)).executeBatch(targets, values, calldatas);
    }
}
