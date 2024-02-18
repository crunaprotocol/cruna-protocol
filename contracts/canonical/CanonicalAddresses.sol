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
  ICrunaRegistry private constant _CRUNA_REGISTRY = ICrunaRegistry(0xFe4F407dee99B8B5660454613b79A2bC9e628750);

  IERC6551Registry private constant _ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

  ICrunaGuardian private constant _CRUNA_GUARDIAN = ICrunaGuardian(0x82AfcB8c199498264D3aB716CA2f17D73e417ebd);

  // we override this during test coverage, because the instrumentation of the smart contracts makes it different over time
  function _crunaRegistry() internal view virtual returns (ICrunaRegistry) {
    return _CRUNA_REGISTRY;
  }

  function _erc6551Registry() internal view virtual returns (IERC6551Registry) {
    return _ERC6551_REGISTRY;
  }

  function _crunaGuardian() internal view virtual returns (ICrunaGuardian) {
    return _CRUNA_GUARDIAN;
  }

  function crunaRegistry() external view returns (ICrunaRegistry) {
    return _crunaRegistry();
  }

  function erc6551Registry() external view returns (IERC6551Registry) {
    return _erc6551Registry();
  }

  function crunaGuardian() external view returns (ICrunaGuardian) {
    return _crunaGuardian();
  }
}
