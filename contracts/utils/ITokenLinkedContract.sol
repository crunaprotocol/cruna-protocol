// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// this is a reduction of IERC6551Account focusing purely on the bond between the NFT and the contract

/// @dev the ERC-165 identifier for this interface is `0xfc0c546a`
interface ITokenLinkedContract {
  /**
   * @dev Returns the identifier of the non-fungible token which owns the contract.
   *
   * The return value of this function MUST be constant - it MUST NOT change over time.
   *
   * @return chainId       The EIP-155 ID of the chain the token exists on
   * @return tokenContract The contract address of the token
   * @return tokenId       The ID of the token
   */
  function token() external view returns (uint256 chainId, address tokenContract, uint256 tokenId);

  function owner() external view returns (address);

  function tokenAddress() external view returns (address);

  function tokenId() external view returns (uint256);

  function implementation() external view returns (address);
}
