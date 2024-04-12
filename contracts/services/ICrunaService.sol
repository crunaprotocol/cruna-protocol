// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {IERC7656Contract} from "../erc/IERC7656Contract.sol";
import {IVersioned} from "../utils/IVersioned.sol";

/**
 * @title ICrunaService.sol
 * @notice Interface for services
 */
interface ICrunaService is IERC7656Contract, IVersioned {
  /**
   * @notice Initialize the plugin. It must be implemented, but can do nothing is no init is needed.
   */
  function init() external;

  /**
   * @notice Called by the manager to know if the plugin is an ERC721 account
   */
  function isERC6551Account() external pure returns (bool);

  /**
   * @notice Called when deploying the service to check if it must be managed
   */
  function isManaged() external pure returns (bool);
}
