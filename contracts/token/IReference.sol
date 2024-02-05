// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";

interface IReference {
  function guardian() external view returns (ICrunaGuardian);
  function registry() external view returns (ICrunaRegistry);
  function emitter() external view returns (address);
}
