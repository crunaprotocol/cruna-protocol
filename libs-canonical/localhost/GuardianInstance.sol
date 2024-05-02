// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ICrunaGuardian} from "../guardian/ICrunaGuardian.sol";

/**
 * @title GuardianInstance.sol
 * @notice Returns the address where the guardian have been deployed on localhost
 */
contract GuardianInstance {

  /**
   * @notice Returns the CrunaGuardian contract
   */
  function _crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0x6Fa017798e51705EC464286434aF6aB881f3A254);
  }
}
