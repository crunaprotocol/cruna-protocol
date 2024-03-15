// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICrunaGuardian
 * @notice Manages upgrade and cross-chain execution settings for accounts
 */
interface ICrunaGuardian {
  /**
   * @notice Emitted when a trusted implementation is updated
   * @param nameId The bytes4 nameId of the implementation
   * @param implementation The address of the implementation
   * @param trusted Whether the implementation is marked as a trusted or marked as no more trusted
   * @param requires The version of the manager required by the implementation
   */
  event TrustedImplementationUpdated(bytes4 indexed nameId, address indexed implementation, bool trusted, uint256 requires);

  /**
   * @notice Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * @param nameId The bytes4 nameId of the implementation
   * @param implementation The address of the implementation
   * @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
   * @param requires The version of the manager required by the implementation (for plugins)
   * Notice that for managers requires will always be 1
   */
  function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted, uint256 requires) external;

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param nameId The bytes4 nameId of the implementation
   * @param implementation The address of the implementation
   * @return The version of the manager required by a trusted implementation. If it is 0, it means
   * the implementation is not trusted
   */
  function trustedImplementation(bytes4 nameId, address implementation) external view returns (uint256);
}
