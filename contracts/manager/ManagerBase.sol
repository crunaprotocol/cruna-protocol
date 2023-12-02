// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {FlexiGuardian} from "./FlexiGuardian.sol";
import {Versioned} from "../utils/Versioned.sol";

//import {console} from "hardhat/console.sol";

contract ManagerBase is Context, Versioned {
  error NotTheTokenOwner();
  error InvalidImplementation();
  error InvalidVersion();

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  bytes32 internal _nameHash;
  FlexiGuardian public guardian;

  uint256 public implementationVersion;

  constructor() {
    implementationVersion = version();
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

  function tokenAddress() public view returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  function upgrade(address implementation_) external virtual {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (!guardian.isTrustedImplementation(_nameHash, implementation_)) revert InvalidImplementation();
    uint256 _version = Versioned(implementation_).version();
    if (_version <= implementationVersion) revert InvalidVersion();
    implementationVersion = _version;
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  function getImplementation() external view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }
}
