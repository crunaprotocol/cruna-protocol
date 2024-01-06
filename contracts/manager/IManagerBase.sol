// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {IBoundContract} from "../utils/IBoundContract.sol";
import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {IGuardian} from "../utils/IGuardian.sol";

//import {console} from "hardhat/console.sol";

interface IVault {
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;
  function emitLockedEvent(uint256 tokenId, bool locked_) external;
  function guardian() external view returns (IGuardian);
  function registry() external view returns (ICrunaRegistry);
  function managerOf(uint256 tokenId) external view returns (address);
}

interface IImplementation {
  function version() external pure returns (uint256);
  function nameId() external returns (bytes4);
}

interface ManagerBase is IBoundContract {
  function nameId() external returns (bytes4);

  function guardian() external view returns (IGuardian);

  function registry() external view returns (ICrunaRegistry);

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
