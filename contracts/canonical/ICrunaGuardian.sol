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
   */
  event TrustedImplementationUpdated(bytes4 indexed nameId, address indexed implementation, bool trusted);

  /**
   * @notice Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * @param nameId The bytes4 nameId of the implementation
   * @param implementation The address of the implementation
   * @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
   * Notice that for managers requires will always be 1
   */
  function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted) external;

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param nameId The bytes4 nameId of the implementation
   * @param implementation The address of the implementation
   * @return True if a trusted implementation
   */
  function trustedImplementation(bytes4 nameId, address implementation) external view returns (bool);

  /**
   * @notice Allows to set a chain as a testnet
   * By default, any chain is a mainnet, i.e., does not allow to plug untrusted plugins
   * Since the admin is supposed to renounce to its role in favore of proposers and
   * executors, this function is meant to be called only once, immediately after the deployment
   * @param allowUntrusted_ True if the chain is a testnet
   */
  function allowUntrusted(bool allowUntrusted_) external;

  /**
   * @notice Returns whether the chain is a testnet
   * @return True if the chain is a testnet
   */
  function allowingUntrusted() external view returns (bool);
}
