// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for coverage.
  The equivalents for testnet and mainnet are in the /canonical-addresses folder and managed
  by scripts/set-canonical.js before tests and before deployments
*/

contract CanonicalAddresses {

  ICrunaRegistry internal constant _CRUNA_REGISTRY = ICrunaRegistry(0x47736647413bC6AC9Da48532AABdebDf498Cb774);

  IERC6551Registry internal constant _ERC6551_REGISTRY = IERC6551Registry(0x0e97Ee6f0D32b477a133bd98CA8e0d25B9b532CA);

  ICrunaGuardian internal constant _CRUNA_GUARDIAN = ICrunaGuardian(0x51C91Fa76d2Ae8eE2aa43B274aF530cAcb214A76);

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
