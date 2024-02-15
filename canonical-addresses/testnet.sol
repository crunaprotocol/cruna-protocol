// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

/**
  Canonical addresses for testnet.
*/

contract CanonicalAddresses {
  ICrunaGuardian public constant CRUNA_GUARDIAN = ICrunaGuardian(0xd9752Ce184Ce6E0A81BEB477779CC8E38Cf966EF);

  ICrunaRegistry public constant CRUNA_REGISTRY = ICrunaRegistry(0x5E825D6e792088E59F545af20fB3DB13cCf6cFe5);

  IERC6551Registry public constant ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
}
