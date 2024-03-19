// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title CrunaRegistry
 * @dev Modified registry based on ERC6551Registry
 * https://github.com/erc6551/reference/blob/main/src/ERC6551Registry.sol
 *
 * @notice Manages the creation of token bound accounts
 */
interface IERC7656Registry {
  /**
   * @notice The registry MUST emit the TokenLinkedContractCreated event upon successful account creation.
   * @param contractAddress The address of the created account
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the account is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   */
  event TokenLinkedContractCreated(
    address contractAddress,
    address indexed implementation,
    bytes32 salt,
    uint256 chainId,
    address indexed tokenContract,
    uint256 indexed tokenId
  );

  /**
   * @notice Creates a token bound account for a non-fungible token.
   * If account has already been created, returns the account address without calling create2.
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the account is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   * Emits TokenLinkedContractCreated event.
   * @return account The address of the token bound account
   */
  function createTokenLinkedContract(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) external returns (address account);

  /**
   * @notice Returns the computed token bound account address for a non-fungible token.
   * @param implementation The address of the implementation contract
   * @param salt The salt to use for the create2 operation
   * @param chainId The chain id of the chain where the account is being created
   * @param tokenContract The address of the token contract
   * @param tokenId The id of the token
   * @return account The address of the token bound account
   */
  function tokenLinkedContract(
    address implementation,
    bytes32 salt,
    uint256 chainId,
    address tokenContract,
    uint256 tokenId
  ) external view returns (address account);
}
