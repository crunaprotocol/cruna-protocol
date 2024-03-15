// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

/**
 * @title INamed
 */
interface INamed {
  /**
   * @notice Returns the name id of the contract
   */
  function nameId() external view returns (bytes4);
}
