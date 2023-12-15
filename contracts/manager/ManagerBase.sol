// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {Guardian} from "./Guardian.sol";
import {Versioned} from "../utils/Versioned.sol";

//import {console} from "hardhat/console.sol";

interface IVault {
  function managedTransfer(bytes4 pluginNameHash, uint256 tokenId, address to) external;
  function emitLockedEvent(uint256 tokenId, bool locked_) external;
  function guardian() external view returns (Guardian);
  function registry() external view returns (IERC6551Registry);
}

/**
  @title ManagerBase
  @dev Base contract for managers and plugins
*/
abstract contract ManagerBase is Context, Versioned {
  error NotTheTokenOwner();
  error InvalidImplementation();
  error InvalidVersion();

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  uint256 public implementationVersion;

  constructor() {
    implementationVersion = version();
  }

  function nameHash() public virtual returns (bytes4);

  function guardian() public view virtual returns (Guardian) {
    return vault().guardian();
  }

  function registry() public view virtual returns (IERC6551Registry) {
    return vault().registry();
  }

  function vault() public view virtual returns (IVault) {
    return IVault(tokenAddress());
  }

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  function token() public view virtual returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function tokenAddress() public view virtual returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view virtual returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  function combineBytes4(bytes4 a, bytes4 b) public pure returns (bytes32) {
    return (bytes32(a) >> 192) | (bytes32(b) >> 224);
  }

  function combineBytes4AndString(bytes4 a, string memory b) public pure returns (bytes32) {
    return (bytes32(a) >> 192) | (bytes32(bytes4(keccak256(abi.encodePacked(b)))) >> 224);
  }

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (!guardian().isTrustedImplementation(nameHash(), implementation_)) revert InvalidImplementation();
    uint256 _version = Versioned(implementation_).version();
    if (_version <= implementationVersion) revert InvalidVersion();
    implementationVersion = _version;
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  function getImplementation() external view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
