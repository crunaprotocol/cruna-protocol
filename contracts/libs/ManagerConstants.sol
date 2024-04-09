// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

/**
 * @title ManagerConstants
 * @notice Constants for the manager. Using functions instead of state variables makes easier to manage future upgrades.
 */
library ManagerConstants {
  /**
   * @notice The maximum number of actors that can be added to the manager
   */
  function maxActors() internal pure returns (uint256) {
    return 16;
  }

  /**
   * @notice Equivalent to bytes4(keccak256("PROTECTOR"))
   */
  function protectorId() internal pure returns (bytes4) {
    return 0x245ac14a;
  }

  /**
   * @notice Equivalent to bytes4(keccak256("SAFE_RECIPIENT"))
   */
  function safeRecipientId() internal pure returns (bytes4) {
    return 0xb58bf73a;
  }

  /**
   * @notice The gas passed to the Protected NFT when asking to emit a Locked event
   */
  function gasToEmitLockedEvent() internal pure returns (uint256) {
    return 9_000;
  }

  /**
   * @notice The gas passed to plugins when asking to them mark the plugin as must-be-reset
   */
  function gasToResetPlugin() internal pure returns (uint256) {
    return 9_000;
  }
}
