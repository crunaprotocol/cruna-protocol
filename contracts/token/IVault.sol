// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";

//import {console} from "hardhat/console.sol";

interface IVault {
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;
  function guardian() external view returns (ICrunaGuardian);
  function registry() external view returns (ICrunaRegistry);
  function emitter() external view returns (address);
  function managerOf(uint256 tokenId) external view returns (address);
}
