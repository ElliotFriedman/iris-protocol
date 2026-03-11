// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IrisDeployer} from "../../src/deployers/IrisDeployer.sol";
import {IrisAccount} from "../../src/IrisAccount.sol";
import {Delegation, Action, Caveat} from "../../src/interfaces/IERC7710.sol";

/// @title IrisTestBase
/// @notice Shared test base contract for all Iris Protocol integration tests.
/// @dev Deploys all Iris contracts via the same IrisDeployer fixture used by deploy scripts,
///      guaranteeing tests exercise the exact same deployment path as mainnet.
abstract contract IrisTestBase is Test {
    IrisDeployer.Deployment internal d;

    function _deployIris() internal {
        d = IrisDeployer.deployAll(address(this), 86_400);
    }

    function _deployIris(address oracleOwner) internal {
        d = IrisDeployer.deployAll(oracleOwner, 86_400);
    }

    // =========================================================================
    // Delegation helpers
    // =========================================================================

    function _helperGetHash(Delegation calldata del) external view returns (bytes32) {
        return d.delegationManager.getDelegationHash(del);
    }

    function _signDelegation(Delegation memory del, uint256 pk)
        internal
        view
        returns (Delegation memory)
    {
        bytes32 dHash = this._helperGetHash(del);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, dHash);
        del.signature = abi.encodePacked(r, s, v);
        return del;
    }

    function _redeemAs(address agent, Delegation memory del, Action memory action) internal {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = del;
        vm.prank(agent);
        d.delegationManager.redeemDelegation(chain, action);
    }

    function _tryRedeemAs(address agent, Delegation memory del, Action memory action)
        internal
        returns (bool)
    {
        Delegation[] memory chain = new Delegation[](1);
        chain[0] = del;
        vm.prank(agent);
        (bool ok,) = address(d.delegationManager).call(
            abi.encodeCall(d.delegationManager.redeemDelegation, (chain, action))
        );
        return ok;
    }

    // =========================================================================
    // Account helpers
    // =========================================================================

    function _createFundedAccount(address owner, uint256 ethAmount)
        internal
        returns (IrisAccount account)
    {
        address acctAddr = d.factory.createAccount(owner, address(d.delegationManager), 0);
        account = IrisAccount(payable(acctAddr));
        vm.deal(address(account), ethAmount);
    }

    function _createFundedAccount(address owner, uint256 ethAmount, uint256 salt)
        internal
        returns (IrisAccount account)
    {
        address acctAddr = d.factory.createAccount(owner, address(d.delegationManager), salt);
        account = IrisAccount(payable(acctAddr));
        vm.deal(address(account), ethAmount);
    }

    // =========================================================================
    // Agent helpers
    // =========================================================================

    function _registerAgent(address operator, string memory metadataURI)
        internal
        returns (uint256 agentId)
    {
        vm.prank(operator);
        agentId = d.agentRegistry.registerAgent(metadataURI);
    }

    function _setReputation(uint256 agentId, uint256 targetScore) internal {
        uint256 currentScore = d.reputationOracle.getReputationScore(agentId);
        if (targetScore > currentScore) {
            uint256 needed = (targetScore - currentScore + 1) / 2; // +2 per positive
            for (uint256 i = 0; i < needed; i++) {
                d.reputationOracle.submitFeedback(agentId, true);
            }
        } else if (targetScore < currentScore) {
            uint256 needed = (currentScore - targetScore + 4) / 5; // -5 per negative
            for (uint256 i = 0; i < needed; i++) {
                d.reputationOracle.submitFeedback(agentId, false);
            }
        }
    }
}
