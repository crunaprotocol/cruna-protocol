// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/CrunaRegistry.sol";

/**
  Canonical addresses for testing and deployment to localhost (using hardhat mnemonic).
  The equivalents for testnet and mainnet are in the /canonical-addresses folder and managed
  by scripts/set-canonical.js before tests and before deployments
*/

library Canonical {

  function crunaRegistry() internal pure returns (ICrunaRegistry) {
    return ICrunaRegistry(0x714Bda695330B2410C0b52449b27b0D3B9e0e7C0);
  }

  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0x8BDf0417F7Bbfd38Db30A5654BB2F827AD9e8EE2);
  }
}
