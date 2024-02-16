// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for testing and deployment to localhost (using hardhat mnemonic).
  The equivalents for testnet and mainnet are in the /canonical-addresses folder and managed
  by scripts/set-canonical.js before tests and before deployments
*/

contract CanonicalAddresses {
  ICrunaRegistry internal constant _CRUNA_REGISTRY = ICrunaRegistry(0xFe4F407dee99B8B5660454613b79A2bC9e628750);

  IERC6551Registry internal constant _ERC6551_REGISTRY = IERC6551Registry(0x15cc2b0c5891aB996A2BA64FF9B4B685cdE762cB);

  ICrunaGuardian internal constant _CRUNA_GUARDIAN = ICrunaGuardian(0xF3385DF79ef342Ba67445f1b474426A94884bAB8);

  function crunaRegistry() external pure returns (ICrunaRegistry) {
    return _CRUNA_REGISTRY;
  }

  function erc6551Registry() external pure returns (IERC6551Registry) {
    return _ERC6551_REGISTRY;
  }

  function crunaGuardian() external pure returns (ICrunaGuardian) {
    return _CRUNA_GUARDIAN;
  }

}
