// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {IERC7656Registry} from "../erc/IERC7656Registry.sol";

/**
 * @title Canonical
 * @notice Returns the address where registries and guardian have been deployed
 * There are two set of addresses. In both, the registry are on the same addresses, but
 * the guardian has a different address for testing and deployment to localhost (using the 2nd
 * and 3rd hardhat standard wallets as proposer and executor).
 * This contract is for production and replaces the dev version when publishing to Npm.
 */
library Canonical {

  /**
   * @notice Returns the ERC7656Registry contract
   */
  function crunaRegistry() internal pure returns (IERC7656Registry) {
    return IERC7656Registry(0x75cCa8eb2B7BCD072410562F10824EC0d3CF0d2e);
  }

  /**
   * @notice Returns the ERC6551Registry contract
   */
  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  /**
   * @notice Returns the CrunaGuardian contract
   */
  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0xB05B9DA88E462b3F77A01AAB8A0Df0598A4f11DA);
  }
}
