// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for mainnet.
*/

contract CanonicalAddresses {
  ICrunaRegistry private constant _CRUNA_REGISTRY = ICrunaRegistry(0x714Bda695330B2410C0b52449b27b0D3B9e0e7C0);

  IERC6551Registry private constant _ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

  ICrunaGuardian private constant _CRUNA_GUARDIAN = ICrunaGuardian(0x8BDf0417F7Bbfd38Db30A5654BB2F827AD9e8EE2);

  // we override this during test coverage, because the instrumentation of the smart contracts makes it different over time
  function _crunaRegistry() internal pure  returns (ICrunaRegistry) {
    return _CRUNA_REGISTRY;
  }

  function _erc6551Registry() internal pure  returns (IERC6551Registry) {
    return _ERC6551_REGISTRY;
  }

  function _crunaGuardian() internal pure  returns (ICrunaGuardian) {
    return _CRUNA_GUARDIAN;
  }

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
