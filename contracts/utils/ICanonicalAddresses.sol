// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";

import {ICrunaGuardian} from "../canonical/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../canonical/CrunaRegistry.sol";

interface ICanonicalAddresses {
  function crunaRegistry() external pure returns (ICrunaRegistry);

  function erc6551Registry() external pure returns (IERC6551Registry);

  function crunaGuardian() external pure returns (ICrunaGuardian);
}
