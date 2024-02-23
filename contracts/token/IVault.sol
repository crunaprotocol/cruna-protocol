// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICanonicalAddresses} from "../canonical/ICanonicalAddresses.sol";

//import {console} from "hardhat/console.sol";

interface IVault is ICanonicalAddresses {
  function vault() external view returns (IVault);
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external;
  function managerOf(uint256 tokenId) external view returns (address);
  function managerEmitter(uint256 _tokenId) external view returns (address);
  function deployPlugin(
    address pluginImplementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external returns (address);
  function deployedToProduction() external view returns (bool);
}
