// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount, PackedUserOperation} from "../../src/IrisAccount.sol";

contract IrisAccountTest is Test {
    IrisAccount account;
    address owner;
    uint256 ownerKey;
    address delegationManager;
    address stranger;

    event DelegationManagerSet(address indexed oldManager, address indexed newManager);
    event DelegationRevoked(bytes32 indexed delegationHash);

    function setUp() public {
        (owner, ownerKey) = makeAddrAndKey("owner");
        delegationManager = makeAddr("delegationManager");
        stranger = makeAddr("stranger");
        account = new IrisAccount(owner, delegationManager);
        vm.deal(address(account), 10 ether);
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    function test_constructor_setsOwnerAndManager() public view {
        assertEq(account.owner(), owner);
        assertEq(account.delegationManager(), delegationManager);
    }

    // -----------------------------------------------------------------------
    // execute
    // -----------------------------------------------------------------------

    function test_execute_ownerCanExecute() public {
        address target = makeAddr("target");
        vm.deal(target, 0);

        vm.prank(owner);
        account.execute(target, 1 ether, "");
        assertEq(target.balance, 1 ether);
    }

    function test_execute_delegationManagerCanExecute() public {
        address target = makeAddr("target");
        vm.prank(delegationManager);
        account.execute(target, 1 ether, "");
        assertEq(target.balance, 1 ether);
    }

    function test_execute_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert(IrisAccount.OnlyOwnerOrDelegationManager.selector);
        account.execute(address(0), 0, "");
    }

    function test_execute_revertsOnFailedCall() public {
        // Call to a contract that reverts
        vm.prank(owner);
        vm.expectRevert(IrisAccount.ExecutionFailed.selector);
        // Call this test contract with bogus calldata that will fail
        account.execute(address(this), 0, abi.encodeWithSignature("nonExistent()"));
    }

    // -----------------------------------------------------------------------
    // executeBatch
    // -----------------------------------------------------------------------

    function test_executeBatch_multipleTargets() public {
        address t1 = makeAddr("t1");
        address t2 = makeAddr("t2");

        address[] memory targets = new address[](2);
        targets[0] = t1;
        targets[1] = t2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1 ether;
        values[1] = 2 ether;

        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = "";
        calldatas[1] = "";

        vm.prank(owner);
        account.executeBatch(targets, values, calldatas);

        assertEq(t1.balance, 1 ether);
        assertEq(t2.balance, 2 ether);
    }

    function test_executeBatch_revertsOnLengthMismatch() public {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](2);
        bytes[] memory calldatas = new bytes[](1);

        vm.prank(owner);
        vm.expectRevert("Length mismatch");
        account.executeBatch(targets, values, calldatas);
    }

    function test_executeBatch_revertsForStranger() public {
        address[] memory targets = new address[](0);
        uint256[] memory values = new uint256[](0);
        bytes[] memory calldatas = new bytes[](0);

        vm.prank(stranger);
        vm.expectRevert(IrisAccount.OnlyOwnerOrDelegationManager.selector);
        account.executeBatch(targets, values, calldatas);
    }

    // -----------------------------------------------------------------------
    // ERC-4337 validateUserOp
    // -----------------------------------------------------------------------

    function test_validateUserOp_validSignature() public {
        bytes32 userOpHash = keccak256("test");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.signature = sig;

        uint256 result = account.validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 0);
    }

    function test_validateUserOp_invalidSignature() public {
        (, uint256 strangerKey) = makeAddrAndKey("stranger2");
        bytes32 userOpHash = keccak256("test");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(strangerKey, ethSignedHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.signature = sig;

        uint256 result = account.validateUserOp(userOp, userOpHash, 0);
        assertEq(result, 1);
    }

    function test_validateUserOp_paysMissingFunds() public {
        bytes32 userOpHash = keccak256("test");
        bytes32 ethSignedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", userOpHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ethSignedHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        PackedUserOperation memory userOp;
        userOp.sender = address(account);
        userOp.signature = sig;

        // Simulate entrypoint calling validateUserOp
        address entrypoint = makeAddr("entrypoint");
        uint256 balBefore = entrypoint.balance;

        vm.prank(entrypoint);
        account.validateUserOp(userOp, userOpHash, 0.5 ether);

        assertEq(entrypoint.balance, balBefore + 0.5 ether);
    }

    // -----------------------------------------------------------------------
    // Delegation management
    // -----------------------------------------------------------------------

    function test_isDelegationValid_defaultTrue() public view {
        bytes32 hash = keccak256("delegation");
        assertTrue(account.isDelegationValid(hash));
    }

    function test_revokeDelegation_setsInvalid() public {
        bytes32 hash = keccak256("delegation");

        vm.prank(owner);
        vm.expectEmit(true, false, false, false);
        emit DelegationRevoked(hash);
        account.revokeDelegation(hash);

        assertFalse(account.isDelegationValid(hash));
    }

    function test_revokeDelegation_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert(IrisAccount.OnlyOwner.selector);
        account.revokeDelegation(keccak256("delegation"));
    }

    // -----------------------------------------------------------------------
    // setDelegationManager
    // -----------------------------------------------------------------------

    function test_setDelegationManager_updatesManager() public {
        address newManager = makeAddr("newManager");

        vm.prank(owner);
        vm.expectEmit(true, true, false, false);
        emit DelegationManagerSet(delegationManager, newManager);
        account.setDelegationManager(newManager);

        assertEq(account.delegationManager(), newManager);
    }

    function test_setDelegationManager_revertsForStranger() public {
        vm.prank(stranger);
        vm.expectRevert(IrisAccount.OnlyOwner.selector);
        account.setDelegationManager(address(0));
    }

    // -----------------------------------------------------------------------
    // Receive ETH
    // -----------------------------------------------------------------------

    function test_receiveEth() public {
        uint256 balBefore = address(account).balance;
        vm.deal(stranger, 1 ether);
        vm.prank(stranger);
        (bool ok,) = address(account).call{value: 1 ether}("");
        assertTrue(ok);
        assertEq(address(account).balance, balBefore + 1 ether);
    }
}
