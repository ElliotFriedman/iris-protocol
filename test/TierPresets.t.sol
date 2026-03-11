// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Caveat} from "../src/interfaces/IERC7710.sol";
import {TierOne} from "../src/presets/TierOne.sol";
import {TierTwo} from "../src/presets/TierTwo.sol";
import {TierThree} from "../src/presets/TierThree.sol";

/// @dev Wrapper contract to expose internal library functions as external calls.
contract TierPresetsWrapper {
    function wrapTierOne(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 dailyCap,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation
    ) external view returns (Caveat[] memory) {
        return TierOne.configureTierOne(
            spendingCapEnforcer, whitelistEnforcer, timeWindowEnforcer, reputationGateEnforcer,
            reputationOracle, agentId, dailyCap, allowedContracts, validUntil, minReputation
        );
    }

    function wrapTierTwo(
        address spendingCapEnforcer,
        address whitelistEnforcer,
        address timeWindowEnforcer,
        address reputationGateEnforcer,
        address singleTxCapEnforcer,
        address reputationOracle,
        uint256 agentId,
        uint256 dailyCap,
        uint256 maxTxValue,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation
    ) external view returns (Caveat[] memory) {
        return TierTwo.configureTierTwo(
            spendingCapEnforcer, whitelistEnforcer, timeWindowEnforcer, reputationGateEnforcer,
            singleTxCapEnforcer, reputationOracle, agentId, dailyCap, maxTxValue,
            allowedContracts, validUntil, minReputation
        );
    }

    // Storage-based approach to avoid stack-too-deep in TierThree.
    TierThree.Enforcers public t3Enforcers;
    TierThree.Params public t3Params;

    address[] private _t3AllowedContracts;

    function setTierThreeParams(
        TierThree.Enforcers memory enforcers,
        address reputationOracle,
        uint256 agentId,
        uint256 weeklyCap,
        uint256 maxTxValue,
        address[] memory allowedContracts,
        uint256 validUntil,
        uint256 minReputation,
        uint256 cooldownPeriod,
        uint256 cooldownThreshold
    ) external {
        t3Enforcers = enforcers;
        _t3AllowedContracts = allowedContracts;
        t3Params = TierThree.Params({
            reputationOracle: reputationOracle,
            agentId: agentId,
            weeklyCap: weeklyCap,
            maxTxValue: maxTxValue,
            allowedContracts: allowedContracts,
            validUntil: validUntil,
            minReputation: minReputation,
            cooldownPeriod: cooldownPeriod,
            cooldownThreshold: cooldownThreshold
        });
    }

    function wrapTierThree() external view returns (Caveat[] memory) {
        TierThree.Enforcers memory enforcers = t3Enforcers;
        TierThree.Params memory params = TierThree.Params({
            reputationOracle: t3Params.reputationOracle,
            agentId: t3Params.agentId,
            weeklyCap: t3Params.weeklyCap,
            maxTxValue: t3Params.maxTxValue,
            allowedContracts: _t3AllowedContracts,
            validUntil: t3Params.validUntil,
            minReputation: t3Params.minReputation,
            cooldownPeriod: t3Params.cooldownPeriod,
            cooldownThreshold: t3Params.cooldownThreshold
        });
        return TierThree.configureTierThree(enforcers, params);
    }
}

contract TierPresetsTest is Test {
    TierPresetsWrapper wrapper;

    address constant SPENDING_CAP = address(0x1);
    address constant WHITELIST = address(0x2);
    address constant TIME_WINDOW = address(0x3);
    address constant REPUTATION_GATE = address(0x4);
    address constant SINGLE_TX_CAP = address(0x5);
    address constant COOLDOWN = address(0x6);
    address constant REPUTATION_ORACLE = address(0xA);

    uint256 constant AGENT_ID = 42;
    uint256 constant DAILY_CAP = 1 ether;
    uint256 constant WEEKLY_CAP = 5 ether;
    uint256 constant MAX_TX_VALUE = 0.5 ether;
    uint256 constant VALID_UNTIL = 1_700_000_000;
    uint256 constant MIN_REPUTATION = 100;
    uint256 constant COOLDOWN_PERIOD = 3600;
    uint256 constant COOLDOWN_THRESHOLD = 0.1 ether;

    address[] allowedContracts;

    function setUp() public {
        wrapper = new TierPresetsWrapper();
        allowedContracts.push(address(0xBEEF));
        allowedContracts.push(address(0xCAFE));
    }

    // ---------------------------------------------------------------
    // Tier One
    // ---------------------------------------------------------------

    function _getTierOneCaveats() internal view returns (Caveat[] memory) {
        return wrapper.wrapTierOne(
            SPENDING_CAP, WHITELIST, TIME_WINDOW, REPUTATION_GATE,
            REPUTATION_ORACLE, AGENT_ID, DAILY_CAP, allowedContracts, VALID_UNTIL, MIN_REPUTATION
        );
    }

    function test_tierOneReturnsFourCaveats() public view {
        assertEq(_getTierOneCaveats().length, 4);
    }

    function test_tierOneCorrectEnforcers() public view {
        Caveat[] memory c = _getTierOneCaveats();
        assertEq(c[0].enforcer, SPENDING_CAP);
        assertEq(c[1].enforcer, WHITELIST);
        assertEq(c[2].enforcer, TIME_WINDOW);
        assertEq(c[3].enforcer, REPUTATION_GATE);
    }

    // ---------------------------------------------------------------
    // Tier Two
    // ---------------------------------------------------------------

    function _getTierTwoCaveats() internal view returns (Caveat[] memory) {
        return wrapper.wrapTierTwo(
            SPENDING_CAP, WHITELIST, TIME_WINDOW, REPUTATION_GATE,
            SINGLE_TX_CAP, REPUTATION_ORACLE, AGENT_ID, DAILY_CAP,
            MAX_TX_VALUE, allowedContracts, VALID_UNTIL, MIN_REPUTATION
        );
    }

    function test_tierTwoReturnsFiveCaveats() public view {
        assertEq(_getTierTwoCaveats().length, 5);
    }

    function test_tierTwoCorrectEnforcers() public view {
        Caveat[] memory c = _getTierTwoCaveats();
        assertEq(c[0].enforcer, SPENDING_CAP);
        assertEq(c[1].enforcer, WHITELIST);
        assertEq(c[2].enforcer, TIME_WINDOW);
        assertEq(c[3].enforcer, REPUTATION_GATE);
        assertEq(c[4].enforcer, SINGLE_TX_CAP);
    }

    // ---------------------------------------------------------------
    // Tier Three
    // ---------------------------------------------------------------

    function _setUpTierThree() internal {
        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: SPENDING_CAP,
            whitelistEnforcer: WHITELIST,
            timeWindowEnforcer: TIME_WINDOW,
            reputationGateEnforcer: REPUTATION_GATE,
            singleTxCapEnforcer: SINGLE_TX_CAP,
            cooldownEnforcer: COOLDOWN
        });
        wrapper.setTierThreeParams(
            enforcers, REPUTATION_ORACLE, AGENT_ID, WEEKLY_CAP, MAX_TX_VALUE,
            allowedContracts, VALID_UNTIL, MIN_REPUTATION, COOLDOWN_PERIOD, COOLDOWN_THRESHOLD
        );
    }

    function test_tierThreeReturnsSixCaveats() public {
        _setUpTierThree();
        assertEq(wrapper.wrapTierThree().length, 6);
    }

    function test_tierThreeCorrectEnforcers() public {
        _setUpTierThree();
        Caveat[] memory c = wrapper.wrapTierThree();
        assertEq(c[0].enforcer, SPENDING_CAP);
        assertEq(c[1].enforcer, WHITELIST);
        assertEq(c[2].enforcer, TIME_WINDOW);
        assertEq(c[3].enforcer, REPUTATION_GATE);
        assertEq(c[4].enforcer, SINGLE_TX_CAP);
        assertEq(c[5].enforcer, COOLDOWN);
    }

    function test_tierThreeCorrectTerms() public {
        _setUpTierThree();
        Caveat[] memory c = wrapper.wrapTierThree();

        (uint256 cap, uint256 period) = abi.decode(c[0].terms, (uint256, uint256));
        assertEq(cap, WEEKLY_CAP);
        assertEq(period, 604_800);

        (uint256 cdPeriod, uint256 cdThreshold) = abi.decode(c[5].terms, (uint256, uint256));
        assertEq(cdPeriod, COOLDOWN_PERIOD);
        assertEq(cdThreshold, COOLDOWN_THRESHOLD);
    }
}
