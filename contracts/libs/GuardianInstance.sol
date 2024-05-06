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
    return ICrunaGuardian(0x0b9A109d25D172cdd24687052e1676CD00d56164);
  }
}
