// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";

import {IVault} from "../token/IVault.sol";
import {INamed} from "../utils/INamed.sol";
import {IBoundContractExtended} from "../utils/IBoundContractExtended.sol";

//import {console} from "hardhat/console.sol";

interface ICrunaManagerBase is IBoundContractExtended, INamed {
  function guardian() external view returns (ICrunaGuardian);

  function registry() external view returns (ICrunaRegistry);

  function emitter(uint256 _tokenId) external view returns (address);

  function vault() external view returns (IVault);

  function combineBytes4(bytes4 a, bytes4 b) external pure returns (bytes32);

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external;

  function getImplementation() external view returns (address);

  // simulate ERC-721 to allow plugins to be deployed via ERC-6551 Registry
  function ownerOf(uint256) external view returns (address);
}
