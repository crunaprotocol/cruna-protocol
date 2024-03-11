// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/CrunaRegistry.sol";

/**
  Canonical for testing testnet and mainnet
*/

library Canonical {

  function crunaRegistry() internal pure returns (ICrunaRegistry) {
    return ICrunaRegistry(0xccCCCb5339Db00811C69f52C384030cB431FBE00);
  }

  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0xCcCCcef4727755933fb5c381C231d44dB34c5442);
  }
}
