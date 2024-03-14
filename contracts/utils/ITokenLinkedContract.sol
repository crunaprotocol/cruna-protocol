// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// this is a reduction of IERC6551Account focusing purely on the bond between the NFT and the contract

/**
 * @title ITokenLinkedContract
 */
interface ITokenLinkedContract {
  /**
   * @dev Returns the token linked to the contract
   * @return chainId The chainId of the token
   * @return tokenContract The address of the token contract
   * @return tokenId The tokenId of the token
   */
  function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

  /// @dev Returns the owner of the token
  function owner() external view returns (address);

  /// @dev Returns the address of the token contract
  function tokenAddress() external view returns (address);

  /// @dev Returns the tokenId of the token
  function tokenId() external view returns (uint256);

  /// @dev Returns the implementation used when creating the contract
  function implementation() external view returns (address);
}
