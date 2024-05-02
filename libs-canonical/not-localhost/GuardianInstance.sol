// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ICrunaGuardian} from "../guardian/ICrunaGuardian.sol";

/**
 * @title GuardianInstance.sol
 * @notice Returns the address where the guardian have been deployed on production
 */
contract GuardianInstance {

  /**
   * @notice Returns the CrunaGuardian contract
   */
  function _crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0x9454BF0e882fcC81a6D2364afD231B372956d272);
  }
}
