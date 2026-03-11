// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisDelegationManager} from "../src/IrisDelegationManager.sol";
import {IrisAccount} from "../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../src/interfaces/IERC7710.sol";
import {ICaveatEnforcer} from "../src/interfaces/ICaveatEnforcer.sol";

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
    // Multi-step delegation chains (authority linking)
    // -----------------------------------------------------------------------

    function test_redeemTwoStepDelegationChain() public {
        // Create an intermediary delegate
        (address intermediary, uint256 intermediaryKey) = makeAddrAndKey("intermediary");
        // Etch IrisAccount at intermediary so it can be a delegator in the chain
        _etchIrisAccountAt(intermediary, intermediary, address(manager));
        vm.deal(intermediary, 10 ether);

        // Root delegation: delegator -> intermediary (authority = address(0))
        Delegation[] memory delegations = new Delegation[](2);
        delegations[1] = _rootDelegation(delegator, intermediary, 1, new Caveat[](0));
        bytes32 rootHash = manager.getDelegationHash(delegations[1]);
        delegations[1].signature = _sign(delegatorKey, rootHash);

        // Leaf delegation: intermediary -> delegate (authority = truncated root hash)
        address authorityAddr = address(uint160(uint256(rootHash)));
        delegations[0] = Delegation({
            delegator: intermediary,
            delegate: delegate,
            authority: authorityAddr,
            caveats: new Caveat[](0),
            salt: 2,
            signature: ""
        });
        bytes32 leafHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(intermediaryKey, leafHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (999))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 999);
    }

    function test_redeemRevertsOnWrongAuthorityLink() public {
        // Create an intermediary delegate
        (address intermediary, uint256 intermediaryKey) = makeAddrAndKey("intermediary2");
        _etchIrisAccountAt(intermediary, intermediary, address(manager));
        vm.deal(intermediary, 10 ether);

        // Root delegation: delegator -> intermediary
        Delegation[] memory delegations = new Delegation[](2);
        delegations[1] = _rootDelegation(delegator, intermediary, 1, new Caveat[](0));
        bytes32 rootHash = manager.getDelegationHash(delegations[1]);
        delegations[1].signature = _sign(delegatorKey, rootHash);

        // Leaf delegation with WRONG authority (not matching the root hash)
        delegations[0] = Delegation({
            delegator: intermediary,
            delegate: delegate,
            authority: address(0xbad),
            caveats: new Caveat[](0),
            salt: 2,
            signature: ""
        });
        bytes32 leafHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(intermediaryKey, leafHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.InvalidDelegationChain.selector);
        manager.redeemDelegation(delegations, action);
    }

    function test_redeemRevertsWhenRootHasNonZeroAuthority() public {
        // Single delegation where authority != address(0) (invalid root)
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = Delegation({
            delegator: delegator,
            delegate: delegate,
            authority: address(0x1234),
            caveats: new Caveat[](0),
            salt: 1,
            signature: ""
        });
        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.InvalidDelegationChain.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // Smart contract wallet signature verification (owner signs for contract)
    // -----------------------------------------------------------------------

    function test_redeemWithOwnerSignatureForContractDelegator() public {
        // Create a smart account where owner != the account address itself.
        // The owner signs the delegation on behalf of the contract delegator.
        (address scOwner, uint256 scOwnerKey) = makeAddrAndKey("scOwner");
        address scAccount = makeAddr("scAccount");
        _etchIrisAccountAt(scAccount, scOwner, address(manager));
        vm.deal(scAccount, 10 ether);

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(scAccount, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        // Owner signs on behalf of the contract delegator
        delegations[0].signature = _sign(scOwnerKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (888))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 888);
    }

    function test_redeemRevertsForContractDelegatorWithWrongSigner() public {
        // Contract delegator where signer is neither the delegator nor its owner
        (address scOwner,) = makeAddrAndKey("scOwner2");
        address scAccount = makeAddr("scAccount2");
        _etchIrisAccountAt(scAccount, scOwner, address(manager));
        vm.deal(scAccount, 10 ether);

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(scAccount, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        // Sign with stranger's key (neither delegator nor owner)
        (, uint256 strangerKey) = makeAddrAndKey("sigStranger");
        delegations[0].signature = _sign(strangerKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.InvalidSignature.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // Caveats with beforeHook and afterHook
    // -----------------------------------------------------------------------

    function test_redeemWithCaveatsCallsBothHooks() public {
        MockCaveatEnforcer enforcer = new MockCaveatEnforcer();

        Caveat[] memory caveats = new Caveat[](1);
        caveats[0] = Caveat({enforcer: address(enforcer), terms: abi.encode(uint256(42))});

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, caveats);

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (555))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 555);
        assertEq(enforcer.beforeHookCallCount(), 1);
        assertEq(enforcer.afterHookCallCount(), 1);
    }

    function test_redeemWithMultipleCaveats() public {
        MockCaveatEnforcer enforcer1 = new MockCaveatEnforcer();
        MockCaveatEnforcer enforcer2 = new MockCaveatEnforcer();

        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(enforcer1), terms: abi.encode(uint256(1))});
        caveats[1] = Caveat({enforcer: address(enforcer2), terms: abi.encode(uint256(2))});

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, caveats);

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (333))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(enforcer1.beforeHookCallCount(), 1);
        assertEq(enforcer1.afterHookCallCount(), 1);
        assertEq(enforcer2.beforeHookCallCount(), 1);
        assertEq(enforcer2.afterHookCallCount(), 1);
    }

    function test_redeemChainWithCaveatsOnMultipleDelegations() public {
        // Two-step chain where both delegations have caveats
        MockCaveatEnforcer enforcer1 = new MockCaveatEnforcer();
        MockCaveatEnforcer enforcer2 = new MockCaveatEnforcer();

        (address intermediary, uint256 intermediaryKey) = makeAddrAndKey("caveatIntermediary");
        _etchIrisAccountAt(intermediary, intermediary, address(manager));
        vm.deal(intermediary, 10 ether);

        Caveat[] memory rootCaveats = new Caveat[](1);
        rootCaveats[0] = Caveat({enforcer: address(enforcer1), terms: ""});

        Caveat[] memory leafCaveats = new Caveat[](1);
        leafCaveats[0] = Caveat({enforcer: address(enforcer2), terms: ""});

        Delegation[] memory delegations = new Delegation[](2);

        // Root delegation with caveats
        delegations[1] = _rootDelegation(delegator, intermediary, 1, rootCaveats);
        bytes32 rootHash = manager.getDelegationHash(delegations[1]);
        delegations[1].signature = _sign(delegatorKey, rootHash);

        // Leaf delegation with caveats
        address authorityAddr = address(uint160(uint256(rootHash)));
        delegations[0] = Delegation({
            delegator: intermediary,
            delegate: delegate,
            authority: authorityAddr,
            caveats: leafCaveats,
            salt: 2,
            signature: ""
        });
        bytes32 leafHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(intermediaryKey, leafHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (444))
        });

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 444);
        // Both enforcers should have been called (before and after)
        assertEq(enforcer1.beforeHookCallCount(), 1);
        assertEq(enforcer1.afterHookCallCount(), 1);
        assertEq(enforcer2.beforeHookCallCount(), 1);
        assertEq(enforcer2.afterHookCallCount(), 1);
    }

    // -----------------------------------------------------------------------
    // revokeDelegation — owner of contract delegator
    // -----------------------------------------------------------------------

    function test_revokeDelegationByOwnerOfContractDelegator() public {
        (address scOwner,) = makeAddrAndKey("revokeOwner");
        address scAccount = makeAddr("revokeAccount");
        _etchIrisAccountAt(scAccount, scOwner, address(manager));

        Delegation memory del = _rootDelegation(scAccount, delegate, 99, new Caveat[](0));
        bytes32 hash = manager.getDelegationHash(del);
        assertFalse(manager.revokedDelegations(hash));

        // Owner of the contract delegator revokes the delegation
        vm.prank(scOwner);
        manager.revokeDelegation(del);
        assertTrue(manager.revokedDelegations(hash));
    }

    function test_revokeDelegationRevertsForStranger() public {
        Delegation memory del = _rootDelegation(delegator, delegate, 99, new Caveat[](0));

        vm.prank(stranger);
        vm.expectRevert(IrisDelegationManager.NotDelegatorOrOwner.selector);
        manager.revokeDelegation(del);
    }

    function test_revokeDelegationRevertsForStrangerOnEOADelegator() public {
        // EOA delegator (no code) — only msg.sender == delegator passes
        address eoaDelegator = makeAddr("eoaDelegator");
        // No code etched, so delegator.code.length == 0

        Delegation memory del = Delegation({
            delegator: eoaDelegator,
            delegate: delegate,
            authority: address(0),
            caveats: new Caveat[](0),
            salt: 1,
            signature: ""
        });

        vm.prank(stranger);
        vm.expectRevert(IrisDelegationManager.NotDelegatorOrOwner.selector);
        manager.revokeDelegation(del);
    }

    // -----------------------------------------------------------------------
    // getDelegationHash — with caveats
    // -----------------------------------------------------------------------

    function test_getDelegationHash_withCaveats() public view {
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(0x1111), terms: abi.encode(uint256(100))});
        caveats[1] = Caveat({enforcer: address(0x2222), terms: abi.encode(uint256(200))});

        Delegation memory d = _rootDelegation(delegator, delegate, 42, caveats);

        bytes32 h1 = manager.getDelegationHash(d);
        bytes32 h2 = manager.getDelegationHash(d);
        assertEq(h1, h2);
        assertTrue(h1 != bytes32(0));

        // Different caveats produce different hash
        Caveat[] memory otherCaveats = new Caveat[](1);
        otherCaveats[0] = Caveat({enforcer: address(0x3333), terms: ""});
        Delegation memory d2 = _rootDelegation(delegator, delegate, 42, otherCaveats);
        bytes32 h3 = manager.getDelegationHash(d2);
        assertTrue(h1 != h3);
    }

    function test_getDelegationHash_differentSalts() public view {
        Delegation memory d1 = _rootDelegation(delegator, delegate, 1, new Caveat[](0));
        Delegation memory d2 = _rootDelegation(delegator, delegate, 2, new Caveat[](0));

        bytes32 h1 = manager.getDelegationHash(d1);
        bytes32 h2 = manager.getDelegationHash(d2);
        assertTrue(h1 != h2);
    }

    function test_getDelegationHash_withAuthority() public view {
        Delegation memory d1 = _rootDelegation(delegator, delegate, 1, new Caveat[](0));
        Delegation memory d2 = Delegation({
            delegator: delegator,
            delegate: delegate,
            authority: address(0xabcd),
            caveats: new Caveat[](0),
            salt: 1,
            signature: ""
        });

        bytes32 h1 = manager.getDelegationHash(d1);
        bytes32 h2 = manager.getDelegationHash(d2);
        assertTrue(h1 != h2);
    }

    // -----------------------------------------------------------------------
    // Delegation to self
    // -----------------------------------------------------------------------

    function test_redeemDelegationToSelf() public {
        // Delegator delegates to themselves
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegator, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (111))
        });

        vm.prank(delegator);
        manager.redeemDelegation(delegations, action);

        assertEq(mockTarget.value(), 111);
    }

    // -----------------------------------------------------------------------
    // domainSeparator
    // -----------------------------------------------------------------------

    function test_domainSeparator() public view {
        bytes32 ds = manager.domainSeparator();
        assertTrue(ds != bytes32(0));
    }

    // -----------------------------------------------------------------------
    // _verifyManagerAuthorized — delegator with no code
    // -----------------------------------------------------------------------

    function test_redeemRevertsWhenDelegatorHasNoCode() public {
        // Pure EOA with no code — staticcall to delegationManager() will fail
        address pureDelegator = makeAddr("pureDelegator");

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(pureDelegator, delegate, 1, new Caveat[](0));

        // We can't properly sign for this delegator but ManagerNotAuthorized
        // should revert before signature check
        (, uint256 randomKey) = makeAddrAndKey("randomSigner");
        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(randomKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.ManagerNotAuthorized.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // ExecutionFailed — target reverts
    // -----------------------------------------------------------------------

    function test_redeemRevertsWhenExecutionFails() public {
        RevertingTarget revertTarget = new RevertingTarget();

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 1, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(revertTarget),
            value: 0,
            callData: abi.encodeCall(RevertingTarget.alwaysReverts, ())
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.ExecutionFailed.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // Revoked delegation in chain
    // -----------------------------------------------------------------------

    function test_redeemRevertsWhenLeafDelegationInChainIsRevoked() public {
        (address intermediary, uint256 intermediaryKey) = makeAddrAndKey("revokeChainIntermediary");
        _etchIrisAccountAt(intermediary, intermediary, address(manager));
        vm.deal(intermediary, 10 ether);

        Delegation[] memory delegations = new Delegation[](2);
        delegations[1] = _rootDelegation(delegator, intermediary, 1, new Caveat[](0));
        bytes32 rootHash = manager.getDelegationHash(delegations[1]);
        delegations[1].signature = _sign(delegatorKey, rootHash);

        address authorityAddr = address(uint160(uint256(rootHash)));
        delegations[0] = Delegation({
            delegator: intermediary,
            delegate: delegate,
            authority: authorityAddr,
            caveats: new Caveat[](0),
            salt: 2,
            signature: ""
        });
        bytes32 leafHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(intermediaryKey, leafHash);

        // Revoke the leaf delegation
        vm.prank(intermediary);
        manager.revokeDelegation(delegations[0]);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(abi.encodeWithSelector(IrisDelegationManager.DelegationIsRevoked.selector, leafHash));
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // _verifySignature — contract delegator with no owner() function
    // -----------------------------------------------------------------------

    function test_redeemRevertsForContractWithNoOwnerFunction() public {
        // Deploy a contract that responds to delegationManager() but not owner()
        NoOwnerContract noOwner = new NoOwnerContract(address(manager));
        vm.deal(address(noOwner), 10 ether);

        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(address(noOwner), delegate, 1, new Caveat[](0));

        (, uint256 randomKey) = makeAddrAndKey("noOwnerSigner");
        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(randomKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.prank(delegate);
        vm.expectRevert(IrisDelegationManager.InvalidSignature.selector);
        manager.redeemDelegation(delegations, action);
    }

    // -----------------------------------------------------------------------
    // Event emission
    // -----------------------------------------------------------------------

    function test_redeemDelegationEmitsEvent() public {
        Delegation[] memory delegations = new Delegation[](1);
        delegations[0] = _rootDelegation(delegator, delegate, 50, new Caveat[](0));

        bytes32 dHash = manager.getDelegationHash(delegations[0]);
        delegations[0].signature = _sign(delegatorKey, dHash);

        Action memory action = Action({
            target: address(mockTarget),
            value: 0,
            callData: abi.encodeCall(MockDMTarget.setValue, (1))
        });

        vm.expectEmit(true, true, true, true);
        emit IrisDelegationManager.DelegationRedeemed(dHash, delegator, delegate);

        vm.prank(delegate);
        manager.redeemDelegation(delegations, action);
    }

    function test_revokeDelegationEmitsEvent() public {
        Delegation memory del = _rootDelegation(delegator, delegate, 50, new Caveat[](0));
        bytes32 hash = manager.getDelegationHash(del);

        vm.expectEmit(true, true, false, true);
        emit IrisDelegationManager.DelegationRevoked(hash, delegator);

        vm.prank(delegator);
        manager.revokeDelegation(del);
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

/// @notice Mock caveat enforcer that tracks hook call counts.
contract MockCaveatEnforcer is ICaveatEnforcer {
    uint256 public beforeHookCallCount;
    uint256 public afterHookCallCount;

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
    ) external override {
        beforeHookCallCount++;
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
    ) external override {
        afterHookCallCount++;
    }
}

/// @notice Target contract that always reverts.
contract RevertingTarget {
    function alwaysReverts() external pure {
        revert("always reverts");
    }
}

/// @notice Contract that responds to delegationManager() but has no owner().
contract NoOwnerContract {
    address public delegationManager;

    constructor(address _manager) {
        delegationManager = _manager;
    }

    function execute(address target, uint256 value, bytes calldata data) external returns (bytes memory) {
        (bool success, bytes memory result) = target.call{value: value}(data);
        require(success, "execution failed");
        return result;
    }

    receive() external payable {}
}
