// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {ITokenLinkedContract} from "./ITokenLinkedContract.sol";



/**
 * @title TokenLinkedContract
 * @dev Abstract contract to link a contract to an NFT
 */
abstract contract TokenLinkedContract is ITokenLinkedContract {
  /**
   * @dev Returns the token linked to the contract
   */
  function token() public view virtual override returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  /**
   * @dev Returns the owner of the token
   */
  function owner() public view virtual override returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  /**
   * @dev Returns the address of the token contract
   */
  function tokenAddress() public view virtual override returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  /**
   * @dev Returns the tokenId of the token
   */
  function tokenId() public view virtual override returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  /**
   * @dev Returns the implementation used when creating the contract
   */
  function implementation() public view virtual override returns (address) {
    return ERC6551AccountLib.implementation();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
