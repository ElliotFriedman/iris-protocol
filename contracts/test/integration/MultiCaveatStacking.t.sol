// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {IrisAccountFactory} from "../../src/IrisAccountFactory.sol";
import {IrisDelegationManager} from "../../src/IrisDelegationManager.sol";
import {IrisAgentRegistry} from "../../src/identity/IrisAgentRegistry.sol";
import {IrisReputationOracle} from "../../src/identity/IrisReputationOracle.sol";
import {SpendingCapEnforcer} from "../../src/caveats/SpendingCapEnforcer.sol";
import {ContractWhitelistEnforcer} from "../../src/caveats/ContractWhitelistEnforcer.sol";
import {FunctionSelectorEnforcer} from "../../src/caveats/FunctionSelectorEnforcer.sol";
import {TimeWindowEnforcer} from "../../src/caveats/TimeWindowEnforcer.sol";
import {ReputationGateEnforcer} from "../../src/caveats/ReputationGateEnforcer.sol";
import {SingleTxCapEnforcer} from "../../src/caveats/SingleTxCapEnforcer.sol";
import {CooldownEnforcer} from "../../src/caveats/CooldownEnforcer.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @notice Target contract with multiple callable functions.
contract DeFiVault {
    uint256 public deposited;
    uint256 public withdrawn;
    uint256 public swapCount;

    function deposit() external payable {
        deposited += msg.value;
    }

    function withdraw(uint256 amount) external {
        withdrawn += amount;
    }

    function swap(uint256 amountIn, uint256 minOut) external payable {
        swapCount++;
    }

    function emergencyShutdown() external {
        // Dangerous — should be restricted
    }

    receive() external payable {}
}

/// @title MultiCaveatStackingTest
/// @notice Tests composability of all 7 caveat enforcers in a single delegation.
///         Validates AND-logic: all caveats must pass for execution to succeed.
contract MultiCaveatStackingTest is Test {
    // Infrastructure
    IrisAccountFactory factory;
    IrisDelegationManager dm;
    IrisAgentRegistry registry;
    IrisReputationOracle oracle;

    // All 7 enforcers
    SpendingCapEnforcer spendingCap;
    ContractWhitelistEnforcer whitelist;
    FunctionSelectorEnforcer funcSelector;
    TimeWindowEnforcer timeWindow;
    ReputationGateEnforcer reputationGate;
    SingleTxCapEnforcer singleTxCap;
    CooldownEnforcer cooldown;

    // Actors
    address owner;
    uint256 ownerKey;
    address agentOperator;
    uint256 agentId;

    // Contracts
    IrisAccount account;
    DeFiVault vault;

    function setUp() public {
        vm.warp(1_000_000);

        dm = new IrisDelegationManager();
        factory = new IrisAccountFactory();
        registry = new IrisAgentRegistry();
        oracle = new IrisReputationOracle(address(registry), address(this));

        spendingCap = new SpendingCapEnforcer();
        whitelist = new ContractWhitelistEnforcer();
        funcSelector = new FunctionSelectorEnforcer();
        timeWindow = new TimeWindowEnforcer();
        reputationGate = new ReputationGateEnforcer();
        singleTxCap = new SingleTxCapEnforcer();
        cooldown = new CooldownEnforcer();

        (owner, ownerKey) = makeAddrAndKey("owner");
        agentOperator = makeAddr("agent");

        vm.prank(agentOperator);
        agentId = registry.registerAgent("ipfs://agent");

        address acctAddr = factory.createAccount(owner, address(dm), 0);
        account = IrisAccount(payable(acctAddr));
        vm.deal(address(account), 1000 ether);

        vault = new DeFiVault();
    }

    // =========================================================================
    // Helpers
    // =========================================================================

    function _helperGetHash(Delegation calldata d) external view returns (bytes32) {
        return dm.getDelegationHash(d);
    }

    function _buildAllCaveatsDelegation(uint256 salt) internal view returns (Delegation memory d) {
        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(vault);

        bytes4[] memory allowedSelectors = new bytes4[](2);
        allowedSelectors[0] = DeFiVault.deposit.selector;
        allowedSelectors[1] = DeFiVault.swap.selector;

        Caveat[] memory caveats = new Caveat[](7);

        // 0: Spending cap — 20 ETH per day
        caveats[0] = Caveat({
            enforcer: address(spendingCap),
            terms: abi.encode(uint256(20 ether), uint256(1 days))
        });

        // 1: Contract whitelist — vault only
        caveats[1] = Caveat({
            enforcer: address(whitelist),
            terms: abi.encode(allowedContracts)
        });

        // 2: Function selector — deposit + swap only
        caveats[2] = Caveat({
            enforcer: address(funcSelector),
            terms: abi.encode(allowedSelectors)
        });

        // 3: Time window — valid for 7 days from now
        caveats[3] = Caveat({
            enforcer: address(timeWindow),
            terms: abi.encode(block.timestamp, block.timestamp + 7 days)
        });

        // 4: Reputation gate — min score 40
        caveats[4] = Caveat({
            enforcer: address(reputationGate),
            terms: abi.encode(address(oracle), agentId, uint256(40))
        });

        // 5: Single tx cap — 10 ETH max per transaction
        caveats[5] = Caveat({
            enforcer: address(singleTxCap),
            terms: abi.encode(uint256(10 ether))
        });

        // 6: Cooldown — 30 minutes between transactions >= 5 ETH
        caveats[6] = Caveat({
            enforcer: address(cooldown),
            terms: abi.encode(uint256(30 minutes), uint256(5 ether))
        });

        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = salt;

        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);
    }

    function _redeem(Delegation memory d, Action memory action) internal {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOperator);
        dm.redeemDelegation(chain, action);
    }

    function _tryRedeem(Delegation memory d, Action memory action) internal returns (bool) {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = d;
        vm.prank(agentOperator);
        (bool ok,) = address(dm).call(
            abi.encodeCall(dm.redeemDelegation, (chain, action))
        );
        return ok;
    }

    // =========================================================================
    // All 7 caveats pass
    // =========================================================================

    function test_allSevenCaveatsPass() public {
        Delegation memory d = _buildAllCaveatsDelegation(1);

        _redeem(d, Action({
            target: address(vault),
            value: 3 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertEq(vault.deposited(), 3 ether);
    }

    // =========================================================================
    // Each caveat individually blocks
    // =========================================================================

    function test_blockedBySpendingCap_allOtherCaveatsPass() public {
        // Reuse same delegation so spending cap tracks cumulatively on same hash
        Delegation memory d = _buildAllCaveatsDelegation(10);

        // First call: 9 ETH
        _redeem(d, Action({
            target: address(vault),
            value: 9 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));

        // Wait for cooldown (first tx was >= 5 ETH threshold)
        vm.warp(block.timestamp + 31 minutes);

        // Second call: 9 ETH — cumulative 18 ETH within 20 cap (reuse same delegation)
        _redeem(d, Action({
            target: address(vault),
            value: 9 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));

        // Wait for cooldown
        vm.warp(block.timestamp + 31 minutes);

        // Third call: 5 ETH — cumulative 23 ETH, exceeds 20 ETH cap
        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 5 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Cumulative spend exceeds daily cap");
    }

    function test_blockedByContractWhitelist_allOtherCaveatsPass() public {
        Delegation memory d = _buildAllCaveatsDelegation(20);

        bool ok = _tryRedeem(d, Action({
            target: makeAddr("rogue"),
            value: 1 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Non-whitelisted contract should be blocked");
    }

    function test_blockedByFunctionSelector_allOtherCaveatsPass() public {
        Delegation memory d = _buildAllCaveatsDelegation(30);

        // emergencyShutdown is not in the allowed selectors
        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 0,
            callData: abi.encodeCall(DeFiVault.emergencyShutdown, ())
        }));
        assertFalse(ok, "Disallowed function selector should be blocked");
    }

    function test_blockedByTimeWindow_allOtherCaveatsPass() public {
        // Build delegation while time window is still valid
        Delegation memory d = _buildAllCaveatsDelegation(40);

        // Fast-forward past the time window (7 days from setUp's block.timestamp)
        vm.warp(block.timestamp + 8 days);

        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 1 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Expired time window should block execution");
    }

    function test_blockedByReputationGate_allOtherCaveatsPass() public {
        // Drop reputation below 40
        oracle.submitFeedback(agentId, false); // 50 -> 45
        oracle.submitFeedback(agentId, false); // 45 -> 40
        oracle.submitFeedback(agentId, false); // 40 -> 35

        Delegation memory d = _buildAllCaveatsDelegation(50);

        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 1 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Low reputation should block execution");
    }

    function test_blockedBySingleTxCap_allOtherCaveatsPass() public {
        Delegation memory d = _buildAllCaveatsDelegation(60);

        // 11 ETH exceeds 10 ETH single tx cap
        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 11 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Single tx cap exceeded should block");
    }

    function test_blockedByCooldown_allOtherCaveatsPass() public {
        // Reuse same delegation so cooldown tracks on same hash
        Delegation memory d = _buildAllCaveatsDelegation(70);

        // First tx: 6 ETH (above 5 ETH threshold) — triggers cooldown
        _redeem(d, Action({
            target: address(vault),
            value: 6 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));

        // Immediately try another high-value tx with same delegation
        bool ok = _tryRedeem(d, Action({
            target: address(vault),
            value: 7 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "Cooldown period not elapsed");
    }

    // =========================================================================
    // Combined scenarios
    // =========================================================================

    function test_whitelistPlusFunctionSelector_onlyAllowedFunctionsOnAllowedContracts() public {
        address[] memory allowedContracts = new address[](1);
        allowedContracts[0] = address(vault);

        bytes4[] memory allowedSelectors = new bytes4[](1);
        allowedSelectors[0] = DeFiVault.deposit.selector;

        Caveat[] memory caveats = new Caveat[](2);
        caveats[0] = Caveat({
            enforcer: address(whitelist),
            terms: abi.encode(allowedContracts)
        });
        caveats[1] = Caveat({
            enforcer: address(funcSelector),
            terms: abi.encode(allowedSelectors)
        });

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 80;

        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);

        // deposit on vault — OK
        _redeem(d, Action({
            target: address(vault),
            value: 1 ether,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertEq(vault.deposited(), 1 ether);

        // swap on vault — blocked by function selector
        Delegation memory d2;
        d2.delegator = address(account);
        d2.delegate = agentOperator;
        d2.authority = address(0);
        d2.caveats = caveats;
        d2.salt = 81;
        bytes32 dHash2 = this._helperGetHash(d2);
        (v, r, s) = vm.sign(ownerKey, dHash2);
        d2.signature = abi.encodePacked(r, s, v);

        bool ok = _tryRedeem(d2, Action({
            target: address(vault),
            value: 0,
            callData: abi.encodeCall(DeFiVault.swap, (100, 90))
        }));
        assertFalse(ok, "swap selector not allowed");

        // deposit on rogue contract — blocked by whitelist
        Delegation memory d3;
        d3.delegator = address(account);
        d3.delegate = agentOperator;
        d3.authority = address(0);
        d3.caveats = caveats;
        d3.salt = 82;
        bytes32 dHash3 = this._helperGetHash(d3);
        (v, r, s) = vm.sign(ownerKey, dHash3);
        d3.signature = abi.encodePacked(r, s, v);

        ok = _tryRedeem(d3, Action({
            target: makeAddr("rogue"),
            value: 0,
            callData: abi.encodeCall(DeFiVault.deposit, ())
        }));
        assertFalse(ok, "rogue contract not whitelisted");
    }

    function test_spendingCapPlusSingleTxCap_bothEnforced() public {
        Caveat[] memory caveats = new Caveat[](2);
        // Daily cap: 15 ETH
        caveats[0] = Caveat({
            enforcer: address(spendingCap),
            terms: abi.encode(uint256(15 ether), uint256(1 days))
        });
        // Per-tx cap: 8 ETH
        caveats[1] = Caveat({
            enforcer: address(singleTxCap),
            terms: abi.encode(uint256(8 ether))
        });

        Delegation memory d;
        d.delegator = address(account);
        d.delegate = agentOperator;
        d.authority = address(0);
        d.caveats = caveats;
        d.salt = 90;

        bytes32 dHash = this._helperGetHash(d);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, dHash);
        d.signature = abi.encodePacked(r, s, v);

        address payable recipient = payable(makeAddr("recipient"));

        // 7 ETH — within both caps
        _redeem(d, Action({target: recipient, value: 7 ether, callData: ""}));
        assertEq(recipient.balance, 7 ether);

        // 9 ETH — exceeds single tx cap (8)
        Delegation memory d2;
        d2.delegator = address(account);
        d2.delegate = agentOperator;
        d2.authority = address(0);
        d2.caveats = caveats;
        d2.salt = 91;
        bytes32 dHash2 = this._helperGetHash(d2);
        (v, r, s) = vm.sign(ownerKey, dHash2);
        d2.signature = abi.encodePacked(r, s, v);

        bool ok = _tryRedeem(d2, Action({target: recipient, value: 9 ether, callData: ""}));
        assertFalse(ok, "Exceeds single tx cap");
    }
}
