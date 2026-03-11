// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisAccount} from "../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";

contract IrisDelegationManagerTest is Test {
    IrisDelegationManager manager;

    address delegate;
    uint256 delegateKey;
    address delegator; // EOA address that also has IrisAccount code etched
    uint256 delegatorKey;
    address stranger = makeAddr("stranger");

    MockDMTarget mockTarget;

    function setUp() public {
        (delegator, delegatorKey) = makeAddrAndKey("delegator");
        (delegate, delegateKey) = makeAddrAndKey("delegate");

        manager = new IrisDelegationManager();
        mockTarget = new MockDMTarget();

        // Etch IrisAccount runtime code at the delegator EOA address so it
        // responds to delegationManager() and execute() calls, while also
        // being the address whose private key we hold for signing.
        _etchIrisAccountAt(delegator, delegator, address(manager));

        vm.deal(delegator, 10 ether);
    }

    // -----------------------------------------------------------------------
    // redeemDelegation — success
    // -----------------------------------------------------------------------

    function test_redeemDelegationSuccess() public {
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (777))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 777);
    }

    // -----------------------------------------------------------------------
    // redeemDelegation — reverts
    // -----------------------------------------------------------------------

    function test_redeemRevertsOnEmptyChain() public {
        Delegation[] memory empty = new Delegation[](0);
        Action memory action = Action({target: address(0), value: 0, callData: ""});

        vm.expectRevert(IrisDelegationManager.EmptyDelegationChain.selector);
        manager.redeemDelegation(empty, action);
    }

    function test_redeemRevertsOnRevokedDelegation() public {
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        // Revoke the delegation on the manager
        vm.prank(delegator);
        manager.revokeDelegation(delegations[0]);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(abi.encodeWithSelector(IrisDelegationManager.DelegationIsRevoked.selector, dHash));
        manager.redeemDelegation(delegations, action);
    }

    function test_redeemRevertsOnInvalidSignature() public {
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, new Caveat[](0));

        // Sign with the wrong key (delegate's key instead of delegator's)
        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegateKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.InvalidSignature.selector);
        manager.redeemDelegation(delegations, action);
    }

    function test_redeemRevertsWhenManagerNotAuthorized() public {
        // Create a new delegator EOA with IrisAccount code whose delegationManager
        // is NOT the manager contract.
        (address badDelegator, uint256 badDelegatorKey) = makeAddrAndKey("badDelegator");
        _etchIrisAccountAt(badDelegator, badDelegator, address(0xdead));

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(badDelegator, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(badDelegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.ManagerNotAuthorized.selector);
        manager.redeemDelegation(delegations, action);
    }

    function test_redeemRevertsWhenSenderNotDelegate() public {
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        // Call from stranger, not delegate
        vm.prank(stranger);
        vm.expectRevert(IrisDelegationManager.InvalidDelegationChain.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // revokeDelegation
    // -----------------------------------------------------------------------

    function test_revokeDelegation() public {
        Delegation memory del = _rootDelegation(delegator, delegate, 99, new Caveat[](0));
        bytes32 hash = manager.getDelegationHash(del);
        assertFalse(manager.revokedDelegations(hash));

        vm.prank(delegator);
        manager.revokeDelegation(del);
        assertTrue(manager.revokedDelegations(hash));
    }

    // -----------------------------------------------------------------------
    // getDelegationHash
    // -----------------------------------------------------------------------

    function test_getDelegationHash_deterministic() public view {
        Delegation memory d = _rootDelegation(delegator, delegate, 42, new Caveat[](0));

        bytes32 h1 = manager.getDelegationHash(d);
        bytes32 h2 = manager.getDelegationHash(d);
        assertEq(h1, h2);
        assertTrue(h1 != bytes32(0));
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /// @dev Etches IrisAccount runtime bytecode at `target` and writes storage
    ///      slots for owner (slot 0) and delegationManager (slot 1).
    function _etchIrisAccountAt(address target, address _owner, address _manager) internal {
        // Deploy a reference IrisAccount to grab its runtime code
        IrisAccount ref = new IrisAccount(_owner, _manager);
        vm.etch(target, address(ref).code);
        // slot 0 = owner
        vm.store(target, bytes32(uint256(0)), bytes32(uint256(uint160(_owner))));
        // slot 1 = delegationManager
        vm.store(target, bytes32(uint256(1)), bytes32(uint256(uint160(_manager))));
    }

    function _rootDelegation(
        address _delegator,
        address _delegate,
        uint256 _salt,
        Caveat[] memory _caveats
    ) internal pure returns (Delegation memory) {
        return Delegation({
            delegator: _delegator,
            delegate: _delegate,
            authority: address(0),
            caveats: _caveats,
            salt: _salt,
            signature: ""
        });
    }

    function _sign(uint256 privKey, bytes32 digest) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        return abi.encodePacked(r, s, v);
    }
}

/// @notice Simple target contract used by delegation manager tests.
contract MockDMTarget {
    uint256 public value;

    function setValue(uint256 v) external {
        value = v;
    }
}
