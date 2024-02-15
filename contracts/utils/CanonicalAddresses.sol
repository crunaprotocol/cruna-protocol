// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for testing and deployment to localhost (using hardhat mnemonic).
  The equivalent for production is in the /canonical-addresses folder
*/

contract CanonicalAddresses {

  ICrunaRegistry public constant CRUNA_REGISTRY = ICrunaRegistry(0xFe4F407dee99B8B5660454613b79A2bC9e628750);

  IERC6551Registry public constant ERC6551_REGISTRY = IERC6551Registry(0x15cc2b0c5891aB996A2BA64FF9B4B685cdE762cB);

  ICrunaGuardian public constant CRUNA_GUARDIAN = ICrunaGuardian(0x3705453Bdbc06e12D3AD40f58aaCd2186262163F);

}
