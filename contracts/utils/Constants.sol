// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {ICrunaRegistry} from "./CrunaRegistry.sol";

contract Constants {
  ICrunaGuardian private constant _CRUNA_GUARDIAN = ICrunaGuardian(0x3C0F933a1Ca14De02D01f19Cd9f52a4Db0b6e425);

  ICrunaRegistry private constant _CRUNA_REGISTRY = ICrunaRegistry(0x44ee88e0b817bb7e95e7702fDCD4887A0bA94219);

  IERC6551Registry private constant _ERC6551_REGISTRY = IERC6551Registry(0x000000006551c19487814612e58FE06813775758);
}
