// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimeControlledGovernance} from "./TimeControlledGovernance.sol";

/**
 * @title ICrunaGuardian
 * @notice Manages upgrade and cross-chain execution settings for accounts
 */
interface ICrunaGuardian {
  /**
   * @notice Emitted when a trusted implementation is updated
   * @param implementation The address of the implementation
   * @param trusted Whether the implementation is marked as a trusted or marked as no more trusted
   */
  event Trusted(address indexed implementation, bool trusted);

  /**
   * @notice Sets a given implementation address as trusted, allowing accounts to upgrade to this implementation.
   * @param delay The delay for the operation
   * @param oType The type of operation
   * @param implementation The address of the implementation
   * @param trusted When true, it set the implementation as trusted, when false it removes the implementation from the trusted list
   * Notice that for managers requires will always be 1
   */
  function trust(uint256 delay, TimeControlledGovernance.OperationType oType, address implementation, bool trusted) external;

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param implementation The address of the implementation
   * @return True if a trusted implementation
   */
  function trusted(address implementation) external view returns (bool);
}
