// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IERC7656Linked} from "erc7656/IERC7656Linked.sol";
import {IVersioned} from "../utils/IVersioned.sol";

/**
 * @title ICrunaService.sol
 * @notice Interface for services
 */
interface ICrunaService is IERC7656Linked, IVersioned {
  /**
   * @notice Error returned when trying to initialize the service if not authorized
   */
  error Forbidden();

  /**
   * @notice Initialize the plugin. It must be implemented, but can do nothing is no init is needed.
   * We call this function init to avoid conflicts with the `initialize` function used in
   * upgradeable contracts
   */
  function init(bytes memory data) external;

  /**
   * @notice Called by the manager to know if the plugin is an ERC721 account
   */
  function isERC6551Account() external pure returns (bool);

  /**
   * @notice Called when deploying the service to check if it must be managed
   * An unmanaged service should always return false
   */
  function isManaged() external pure returns (bool);
}
