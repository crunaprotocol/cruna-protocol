// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for testnet.
*/

contract CanonicalAddresses {
  ICrunaGuardian private constant _CRUNA_GUARDIAN = ICrunaGuardian(0xd9752Ce184Ce6E0A81BEB477779CC8E38Cf966EF);

  ICrunaRegistry private constant _CRUNA_REGISTRY = ICrunaRegistry(0x5E825D6e792088E59F545af20fB3DB13cCf6cFe5);

  IERC6551Registry private constant _ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);

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
