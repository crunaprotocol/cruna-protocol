// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/ICrunaRegistry.sol";

/**
 * @title Canonical
 * @dev Returns the address where registries and guardian have been deployed
 * There are two set of addresses. In both, the registry are on the same addresses, but
 * the guardian has a different address for testing and deployment to localhost (using the 2nd
 * and 3rd hardhat standard wallets as proposer and executor).
 * This contract is for production and replaces the dev version when publishing to Npm.
 */
library Canonical {

  /**
   * @dev Returns the CrunaRegistry contract
   */
  function crunaRegistry() internal pure returns (ICrunaRegistry) {
    return ICrunaRegistry(0xccCCCb5339Db00811C69f52C384030cB431FBE00);
  }

  /**
   * @dev Returns the ERC6551Registry contract
   */
  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  /**
   * @dev Returns the CrunaGuardian contract
   */
  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0xCcCCcef4727755933fb5c381C231d44dB34c5442);
  }
}
