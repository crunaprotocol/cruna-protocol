// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/ICrunaRegistry.sol";

/**
 * @title Canonical
 * @notice Returns the address where registries and guardian have been deployed
 * @dev There are two set of addresses. In both, the registry are on the same addresses, but
 * the guardian has a different address for testing and deployment to localhost (using the 2nd
 * and 3rd hardhat standard wallets as proposer and executor).
 * This contract is for development and testing purposes only. When the package is published
 * to Npm, the addresses will be replaced by the actual addresses of the deployed contracts.
 */
library Canonical {

  /**
   * @notice Returns the CrunaRegistry contract
   */
  function crunaRegistry() internal pure returns (ICrunaRegistry) {
    return ICrunaRegistry(0xccCCCb5339Db00811C69f52C384030cB431FBE00);
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
    return ICrunaGuardian(0x5B098ee10B085507F5520c9c760B8107Eb2A4455);
  }
}
