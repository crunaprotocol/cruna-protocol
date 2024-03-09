// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/CrunaRegistry.sol";

/**
  Canonical for testing and deployment to localhost (using hardhat mnemonic).
*/

library Canonical {

  function crunaRegistry() internal pure returns (ICrunaRegistry) {
    return ICrunaRegistry(0xFe4F407dee99B8B5660454613b79A2bC9e628750);
  }

  function erc6551Registry() internal pure returns (IERC6551Registry) {
    return IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
  }

  function crunaGuardian() internal pure returns (ICrunaGuardian) {
    return ICrunaGuardian(0x82AfcB8c199498264D3aB716CA2f17D73e417ebd);
  }
}
