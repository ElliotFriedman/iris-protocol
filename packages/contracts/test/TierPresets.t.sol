// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Caveat} from "../src/interfaces/IERC7710.sol";
import {TierOne} from "../src/presets/TierOne.sol";
import {TierTwo} from "../src/presets/TierTwo.sol";
import {TierThree} from "../src/presets/TierThree.sol";

/// @dev Parameters for TierThree wrapper to avoid stack-too-deep.
struct TierThreeParams {
    address spendingCapEnforcer;
    address whitelistEnforcer;
    address timeWindowEnforcer;
    address reputationGateEnforcer;
    address singleTxCapEnforcer;
    address cooldownEnforcer;
    address reputationOracle;
    uint256 agentId;
    uint256 weeklyCap;
    uint256 maxTxValue;
    address[] allowedContracts;
    uint256 validUntil;
    uint256 minReputation;
    uint256 cooldownPeriod;
    uint256 cooldownThreshold;
}

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
            spendingCapEnforcer,
            whitelistEnforcer,
            timeWindowEnforcer,
            reputationGateEnforcer,
            reputationOracle,
            agentId,
            dailyCap,
            allowedContracts,
            validUntil,
            minReputation
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
            spendingCapEnforcer,
            whitelistEnforcer,
            timeWindowEnforcer,
            reputationGateEnforcer,
            singleTxCapEnforcer,
            reputationOracle,
            agentId,
            dailyCap,
            maxTxValue,
            allowedContracts,
            validUntil,
            minReputation
        );
    }

    // Storage-based approach to avoid stack-too-deep in TierThree.
    address public t3SpendingCap;
    address public t3Whitelist;
    address public t3TimeWindow;
    address public t3ReputationGate;
    address public t3SingleTxCap;
    address public t3Cooldown;
    address public t3ReputationOracle;
    uint256 public t3AgentId;
    uint256 public t3WeeklyCap;
    uint256 public t3MaxTxValue;
    address[] public t3AllowedContracts;
    uint256 public t3ValidUntil;
    uint256 public t3MinReputation;
    uint256 public t3CooldownPeriod;
    uint256 public t3CooldownThreshold;

    function setTierThreeParams(TierThreeParams memory p) external {
        t3SpendingCap = p.spendingCapEnforcer;
        t3Whitelist = p.whitelistEnforcer;
        t3TimeWindow = p.timeWindowEnforcer;
        t3ReputationGate = p.reputationGateEnforcer;
        t3SingleTxCap = p.singleTxCapEnforcer;
        t3Cooldown = p.cooldownEnforcer;
        t3ReputationOracle = p.reputationOracle;
        t3AgentId = p.agentId;
        t3WeeklyCap = p.weeklyCap;
        t3MaxTxValue = p.maxTxValue;
        t3AllowedContracts = p.allowedContracts;
        t3ValidUntil = p.validUntil;
        t3MinReputation = p.minReputation;
        t3CooldownPeriod = p.cooldownPeriod;
        t3CooldownThreshold = p.cooldownThreshold;
    }

    function wrapTierThree() external view returns (Caveat[] memory) {
        TierThree.Enforcers memory enforcers = TierThree.Enforcers({
            spendingCapEnforcer: t3SpendingCap,
            whitelistEnforcer: t3Whitelist,
            timeWindowEnforcer: t3TimeWindow,
            reputationGateEnforcer: t3ReputationGate,
            singleTxCapEnforcer: t3SingleTxCap,
            cooldownEnforcer: t3Cooldown
        });
        TierThree.Params memory params = TierThree.Params({
            reputationOracle: t3ReputationOracle,
            agentId: t3AgentId,
            weeklyCap: t3WeeklyCap,
            maxTxValue: t3MaxTxValue,
            allowedContracts: t3AllowedContracts,
            validUntil: t3ValidUntil,
            minReputation: t3MinReputation,
            cooldownPeriod: t3CooldownPeriod,
            cooldownThreshold: t3CooldownThreshold
        });
        return TierThree.configureTierThree(enforcers, params);
    }
}

contract TierPresetsTest is Test {
    TierPresetsWrapper wrapper;

    // Dummy enforcer addresses
    address constant SPENDING_CAP = address(0x1);
    address constant WHITELIST = address(0x2);
    address constant TIME_WINDOW = address(0x3);
    address constant REPUTATION_GATE = address(0x4);
    address constant SINGLE_TX_CAP = address(0x5);
    address constant COOLDOWN = address(0x6);

    // Dummy parameter values
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
            REPUTATION_ORACLE, AGENT_ID, DAILY_CAP, allowedContracts,
            VALID_UNTIL, MIN_REPUTATION
        );
    }

    function test_tierOneReturnsFourCaveats() public view {
        Caveat[] memory caveats = _getTierOneCaveats();
        assertEq(caveats.length, 4, "TierOne should return 4 caveats");
    }

    function test_tierOneCorrectEnforcers() public view {
        Caveat[] memory caveats = _getTierOneCaveats();
        assertEq(caveats[0].enforcer, SPENDING_CAP, "caveat 0: SpendingCap enforcer");
        assertEq(caveats[1].enforcer, WHITELIST, "caveat 1: Whitelist enforcer");
        assertEq(caveats[2].enforcer, TIME_WINDOW, "caveat 2: TimeWindow enforcer");
        assertEq(caveats[3].enforcer, REPUTATION_GATE, "caveat 3: ReputationGate enforcer");
    }

    function test_tierOneCorrectTerms() public view {
        Caveat[] memory caveats = _getTierOneCaveats();

        // Caveat 0: SpendingCap terms — (dailyCap, 86400)
        (uint256 cap, uint256 period) = abi.decode(caveats[0].terms, (uint256, uint256));
        assertEq(cap, DAILY_CAP, "spending cap value");
        assertEq(period, 86_400, "spending cap daily period");

        // Caveat 1: ContractWhitelist terms — (address[])
        address[] memory decoded = abi.decode(caveats[1].terms, (address[]));
        assertEq(decoded.length, 2, "whitelist length");
        assertEq(decoded[0], address(0xBEEF), "whitelist[0]");
        assertEq(decoded[1], address(0xCAFE), "whitelist[1]");

        // Caveat 2: TimeWindow terms — (block.timestamp, validUntil)
        (uint256 start, uint256 end_) = abi.decode(caveats[2].terms, (uint256, uint256));
        assertEq(start, block.timestamp, "time window start");
        assertEq(end_, VALID_UNTIL, "time window end");

        // Caveat 3: ReputationGate terms — (oracle, agentId, minReputation)
        (address oracle, uint256 aid, uint256 rep) =
            abi.decode(caveats[3].terms, (address, uint256, uint256));
        assertEq(oracle, REPUTATION_ORACLE, "reputation oracle");
        assertEq(aid, AGENT_ID, "agent id");
        assertEq(rep, MIN_REPUTATION, "min reputation");
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
        Caveat[] memory caveats = _getTierTwoCaveats();
        assertEq(caveats.length, 5, "TierTwo should return 5 caveats");
    }

    function test_tierTwoCorrectEnforcers() public view {
        Caveat[] memory caveats = _getTierTwoCaveats();
        assertEq(caveats[0].enforcer, SPENDING_CAP, "caveat 0: SpendingCap enforcer");
        assertEq(caveats[1].enforcer, WHITELIST, "caveat 1: Whitelist enforcer");
        assertEq(caveats[2].enforcer, TIME_WINDOW, "caveat 2: TimeWindow enforcer");
        assertEq(caveats[3].enforcer, REPUTATION_GATE, "caveat 3: ReputationGate enforcer");
        assertEq(caveats[4].enforcer, SINGLE_TX_CAP, "caveat 4: SingleTxCap enforcer");
    }

    function test_tierTwoCorrectTerms() public view {
        Caveat[] memory caveats = _getTierTwoCaveats();

        // Caveat 0: SpendingCap — (dailyCap, 86400)
        (uint256 cap, uint256 period) = abi.decode(caveats[0].terms, (uint256, uint256));
        assertEq(cap, DAILY_CAP, "spending cap value");
        assertEq(period, 86_400, "spending cap daily period");

        // Caveat 1: ContractWhitelist
        address[] memory decoded = abi.decode(caveats[1].terms, (address[]));
        assertEq(decoded.length, 2, "whitelist length");
        assertEq(decoded[0], address(0xBEEF), "whitelist[0]");
        assertEq(decoded[1], address(0xCAFE), "whitelist[1]");

        // Caveat 2: TimeWindow
        (uint256 start, uint256 end_) = abi.decode(caveats[2].terms, (uint256, uint256));
        assertEq(start, block.timestamp, "time window start");
        assertEq(end_, VALID_UNTIL, "time window end");

        // Caveat 3: ReputationGate
        (address oracle, uint256 aid, uint256 rep) =
            abi.decode(caveats[3].terms, (address, uint256, uint256));
        assertEq(oracle, REPUTATION_ORACLE, "reputation oracle");
        assertEq(aid, AGENT_ID, "agent id");
        assertEq(rep, MIN_REPUTATION, "min reputation");

        // Caveat 4: SingleTxCap — (maxTxValue)
        uint256 maxTx = abi.decode(caveats[4].terms, (uint256));
        assertEq(maxTx, MAX_TX_VALUE, "single tx cap");
    }

    // ---------------------------------------------------------------
    // Tier Three
    // ---------------------------------------------------------------

    function _setUpTierThreeParams() internal {
        TierThreeParams memory p = TierThreeParams({
            spendingCapEnforcer: SPENDING_CAP,
            whitelistEnforcer: WHITELIST,
            timeWindowEnforcer: TIME_WINDOW,
            reputationGateEnforcer: REPUTATION_GATE,
            singleTxCapEnforcer: SINGLE_TX_CAP,
            cooldownEnforcer: COOLDOWN,
            reputationOracle: REPUTATION_ORACLE,
            agentId: AGENT_ID,
            weeklyCap: WEEKLY_CAP,
            maxTxValue: MAX_TX_VALUE,
            allowedContracts: allowedContracts,
            validUntil: VALID_UNTIL,
            minReputation: MIN_REPUTATION,
            cooldownPeriod: COOLDOWN_PERIOD,
            cooldownThreshold: COOLDOWN_THRESHOLD
        });
        wrapper.setTierThreeParams(p);
    }

    function _getTierThreeCaveats() internal returns (Caveat[] memory) {
        _setUpTierThreeParams();
        return wrapper.wrapTierThree();
    }

    function test_tierThreeReturnsSixCaveats() public {
        Caveat[] memory caveats = _getTierThreeCaveats();
        assertEq(caveats.length, 6, "TierThree should return 6 caveats");
    }

    function test_tierThreeCorrectEnforcers() public {
        Caveat[] memory caveats = _getTierThreeCaveats();
        assertEq(caveats[0].enforcer, SPENDING_CAP, "caveat 0: SpendingCap enforcer");
        assertEq(caveats[1].enforcer, WHITELIST, "caveat 1: Whitelist enforcer");
        assertEq(caveats[2].enforcer, TIME_WINDOW, "caveat 2: TimeWindow enforcer");
        assertEq(caveats[3].enforcer, REPUTATION_GATE, "caveat 3: ReputationGate enforcer");
        assertEq(caveats[4].enforcer, SINGLE_TX_CAP, "caveat 4: SingleTxCap enforcer");
        assertEq(caveats[5].enforcer, COOLDOWN, "caveat 5: Cooldown enforcer");
    }

    function test_tierThreeCorrectTerms() public {
        Caveat[] memory caveats = _getTierThreeCaveats();

        // Caveat 0: SpendingCap — (weeklyCap, 604800)
        (uint256 cap, uint256 period) = abi.decode(caveats[0].terms, (uint256, uint256));
        assertEq(cap, WEEKLY_CAP, "spending cap value");
        assertEq(period, 604_800, "spending cap weekly period");

        // Caveat 1: ContractWhitelist
        address[] memory decoded = abi.decode(caveats[1].terms, (address[]));
        assertEq(decoded.length, 2, "whitelist length");
        assertEq(decoded[0], address(0xBEEF), "whitelist[0]");
        assertEq(decoded[1], address(0xCAFE), "whitelist[1]");

        // Caveat 2: TimeWindow
        (uint256 start, uint256 end_) = abi.decode(caveats[2].terms, (uint256, uint256));
        assertEq(start, block.timestamp, "time window start");
        assertEq(end_, VALID_UNTIL, "time window end");

        // Caveat 3: ReputationGate
        (address oracle, uint256 aid, uint256 rep) =
            abi.decode(caveats[3].terms, (address, uint256, uint256));
        assertEq(oracle, REPUTATION_ORACLE, "reputation oracle");
        assertEq(aid, AGENT_ID, "agent id");
        assertEq(rep, MIN_REPUTATION, "min reputation");

        // Caveat 4: SingleTxCap
        uint256 maxTx = abi.decode(caveats[4].terms, (uint256));
        assertEq(maxTx, MAX_TX_VALUE, "single tx cap");

        // Caveat 5: Cooldown — (cooldownPeriod, cooldownThreshold)
        (uint256 cdPeriod, uint256 cdThreshold) =
            abi.decode(caveats[5].terms, (uint256, uint256));
        assertEq(cdPeriod, COOLDOWN_PERIOD, "cooldown period");
        assertEq(cdThreshold, COOLDOWN_THRESHOLD, "cooldown threshold");
    }
}
