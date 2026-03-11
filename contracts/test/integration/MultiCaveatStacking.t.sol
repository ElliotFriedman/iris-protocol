// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IrisTestBase} from "../helpers/IrisTestBase.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

contract DeFiVault {
    uint256 public deposited;
    uint256 public withdrawn;
    uint256 public swapCount;

    function deposit() external payable { deposited += msg.value; }
    function withdraw(uint256 amount) external { withdrawn += amount; }
    function swap(uint256 amountIn, uint256 minOut) external payable { swapCount++; }
    function emergencyShutdown() external {}
    receive() external payable {}
}

/// @title MultiCaveatStackingTest
/// @notice Tests composability of all 7 caveat enforcers in a single delegation.
/// @dev Uses IrisDeployer fixture via IrisTestBase for deployment parity with mainnet scripts.
contract MultiCaveatStackingTest is IrisTestBase {
    address owner;
    uint256 ownerKey;
    address agentOperator;
    uint256 agentId;

    IrisAccount account;
    DeFiVault vault;

    function setUp() public {
        vm.warp(1_000_000);
        _deployIris();

        (owner, ownerKey) = makeAddrAndKey("owner");
        agentOperator = makeAddr("agent");
        agentId = _registerAgent(agentOperator, "ipfs://agent");
        account = _createFundedAccount(owner, 1000 ether);
        vault = new DeFiVault();
    }

    function _buildAllCaveatsDelegation(uint256 salt) internal view returns (Delegation memory del) {
        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(vault);

        bytes4[] memory allowedSelectors = new bytes4[](2);
        allowedSelectors[0] = DeFiVault.deposit.selector;
        allowedSelectors[1] = DeFiVault.swap.selector;

        Caveat[] memory caveats = new Caveat[](7);
        caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(20 ether), uint256(1 days))});
        caveats[1] = Caveat({enforcer: address(d.contractWhitelist), terms: abi.encode(allowedContracts)});
        caveats[2] = Caveat({enforcer: address(d.functionSelector), terms: abi.encode(allowedSelectors)});
        caveats[3] = Caveat({enforcer: address(d.timeWindow), terms: abi.encode(block.timestamp, block.timestamp + 7 days)});
        caveats[4] = Caveat({enforcer: address(d.reputationGate), terms: abi.encode(address(d.reputationOracle), agentId, uint256(40))});
        caveats[5] = Caveat({enforcer: address(d.singleTxCap), terms: abi.encode(uint256(10 ether))});
        caveats[6] = Caveat({enforcer: address(d.cooldown), terms: abi.encode(uint256(30 minutes), uint256(5 ether))});

        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = salt;
        del = _signDelegation(del, ownerKey);
    }

    function test_allSevenCaveatsPass() public {
        Delegation memory del = _buildAllCaveatsDelegation(1);
        _redeemAs(agentOperator, del, Action({target: address(vault), value: 3 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertEq(vault.deposited(), 3 ether);
    }

    function test_blockedBySpendingCap_allOtherCaveatsPass() public {
        Delegation memory del = _buildAllCaveatsDelegation(10);
        _redeemAs(agentOperator, del, Action({target: address(vault), value: 9 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        vm.warp(block.timestamp + 31 minutes);
        _redeemAs(agentOperator, del, Action({target: address(vault), value: 9 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        vm.warp(block.timestamp + 31 minutes);
        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(vault), value: 5 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_blockedByContractWhitelist_allOtherCaveatsPass() public {
        bool ok = _tryRedeemAs(agentOperator, _buildAllCaveatsDelegation(20), Action({target: makeAddr("rogue"), value: 1 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_blockedByFunctionSelector_allOtherCaveatsPass() public {
        bool ok = _tryRedeemAs(agentOperator, _buildAllCaveatsDelegation(30), Action({target: address(vault), value: 0, callData: abi.encodeCall(DeFiVault.emergencyShutdown, ())}));
        assertFalse(ok);
    }

    function test_blockedByTimeWindow_allOtherCaveatsPass() public {
        Delegation memory del = _buildAllCaveatsDelegation(40);
        vm.warp(block.timestamp + 8 days);
        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(vault), value: 1 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_blockedByReputationGate_allOtherCaveatsPass() public {
        d.reputationOracle.submitFeedback(agentId, false);
        d.reputationOracle.submitFeedback(agentId, false);
        d.reputationOracle.submitFeedback(agentId, false);
        bool ok = _tryRedeemAs(agentOperator, _buildAllCaveatsDelegation(50), Action({target: address(vault), value: 1 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_blockedBySingleTxCap_allOtherCaveatsPass() public {
        bool ok = _tryRedeemAs(agentOperator, _buildAllCaveatsDelegation(60), Action({target: address(vault), value: 11 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_blockedByCooldown_allOtherCaveatsPass() public {
        Delegation memory del = _buildAllCaveatsDelegation(70);
        _redeemAs(agentOperator, del, Action({target: address(vault), value: 6 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        bool ok = _tryRedeemAs(agentOperator, del, Action({target: address(vault), value: 7 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_whitelistPlusFunctionSelector_onlyAllowedFunctionsOnAllowedContracts() public {
        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(vault);
        bytes4[] memory allowedSelectors = new bytes4[](1);
        allowedSelectors[0] = DeFiVault.deposit.selector;

        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(d.contractWhitelist), terms: abi.encode(allowedContracts)});
        caveats[1] = Caveat({enforcer: address(d.functionSelector), terms: abi.encode(allowedSelectors)});

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 80;
        del = _signDelegation(del, ownerKey);

        _redeemAs(agentOperator, del, Action({target: address(vault), value: 1 ether, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertEq(vault.deposited(), 1 ether);

        // swap blocked
        Delegation memory del2;
        del2.delegator = address(account);
        del2.delegate = agentOperator;
        del2.authority = address(0);
        del2.caveats = caveats;
        del2.salt = 81;
        del2 = _signDelegation(del2, ownerKey);
        bool ok = _tryRedeemAs(agentOperator, del2, Action({target: address(vault), value: 0, callData: abi.encodeCall(DeFiVault.swap, (100, 90))}));
        assertFalse(ok);

        // rogue contract blocked
        Delegation memory del3;
        del3.delegator = address(account);
        del3.delegate = agentOperator;
        del3.authority = address(0);
        del3.caveats = caveats;
        del3.salt = 82;
        del3 = _signDelegation(del3, ownerKey);
        ok = _tryRedeemAs(agentOperator, del3, Action({target: makeAddr("rogue"), value: 0, callData: abi.encodeCall(DeFiVault.deposit, ())}));
        assertFalse(ok);
    }

    function test_spendingCapPlusSingleTxCap_bothEnforced() public {
        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({enforcer: address(d.spendingCap), terms: abi.encode(uint256(15 ether), uint256(1 days))});
        caveats[1] = Caveat({enforcer: address(d.singleTxCap), terms: abi.encode(uint256(8 ether))});

        Delegation memory del;
        del.delegator = address(account);
        del.delegate = agentOperator;
        del.authority = address(0);
        del.caveats = caveats;
        del.salt = 90;
        del = _signDelegation(del, ownerKey);

        address payable recipient = payable(makeAddr("recipient"));
        _redeemAs(agentOperator, del, Action({target: recipient, value: 7 ether, callData: ""}));
        assertEq(recipient.balance, 7 ether);

        Delegation memory del2;
        del2.delegator = address(account);
        del2.delegate = agentOperator;
        del2.authority = address(0);
        del2.caveats = caveats;
        del2.salt = 91;
        del2 = _signDelegation(del2, ownerKey);
        bool ok = _tryRedeemAs(agentOperator, del2, Action({target: recipient, value: 9 ether, callData: ""}));
        assertFalse(ok);
    }
}
