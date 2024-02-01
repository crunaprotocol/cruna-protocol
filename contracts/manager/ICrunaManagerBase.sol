// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IBoundContract} from "../utils/IBoundContract.sol";
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

interface IImplementation {
  function version() external pure returns (uint256);
  function nameId() external returns (bytes4);
}

interface ICrunaManagerBase is IBoundContract {
  function nameId() external returns (bytes4);

  function guardian() external view returns (ICrunaGuardian);

  function registry() external view returns (ICrunaRegistry);

  function emitter() external view returns (address);

  function vault() external view returns (IVault);

  function owner() external view returns (address);

  function tokenAddress() external view returns (address);

  function tokenId() external view returns (uint256);

  function combineBytes4(bytes4 a, bytes4 b) external pure returns (bytes32);

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external;

  function getImplementation() external view returns (address);
}
