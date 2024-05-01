// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

import {IERC165, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {IERC7656Contract, IERC7656ContractExtended} from "./IERC7656ContractExtended.sol";

//import "hardhat/console.sol";

/**
 * @title ERC7656Contract.sol
 * @notice Abstract contract to link a contract to an NFT
 */
abstract contract ERC7656Contract is IERC7656ContractExtended, IERC165 {
  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return interfaceId == type(IERC7656Contract).interfaceId;
  }

  /**
   * @notice Returns the token linked to the contract
   */
  function token() public view virtual override returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  /**
   * @notice Returns the owner of the token
   */
  function owner() public view virtual override returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = ERC6551AccountLib.token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  /**
   * @notice Returns the salt used when creating the contract
   */
  function salt() public view virtual override returns (bytes32) {
    return _salt();
  }

  function _salt() internal view returns (bytes32) {
    return ERC6551AccountLib.salt();
  }

  /**
   * @notice Returns the address of the token contract
   */
  function tokenAddress() public view virtual override returns (address) {
    return _tokenAddress();
  }

  function _tokenAddress() internal view returns (address) {
    (, address tokenContract_, ) = ERC6551AccountLib.token();
    return tokenContract_;
  }

  /**
   * @notice Returns the tokenId of the token
   */
  function tokenId() public view virtual override returns (uint256) {
    return _tokenId();
  }

  function _tokenId() internal view returns (uint256) {
    (, , uint256 tokenId_) = ERC6551AccountLib.token();
    return tokenId_;
  }

  /**
   * @notice Returns the implementation used when creating the contract
   */
  function implementation() public view virtual override returns (address) {
    return _implementation();
  }

  function _implementation() internal view returns (address) {
    return ERC6551AccountLib.implementation();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
