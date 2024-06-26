// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaService} from "./ICrunaService.sol";

/**
 * @title ICrunaManagedService.sol
 * @notice Interface for services
 * @dev Technically, services are secondary managers, pluggable in
 * the primary manage, which is CrunaManager.sol
 */
interface ICrunaManagedService is ICrunaService {
  /**
   * @notice The configuration of the plugin
   */
  struct Conf {
    CrunaManager manager;
    // When mustReset is true, the plugin must be reset before being used again.
    // This strategy is needed during transfers to avoid gas issues, because actually resetting the
    // data can be expensive. As a trade-off, the receiver of the protected NFT must reset the plugin.
    uint32 mustBeReset;
  }

  /**
   * @notice Error returned when the plugin is reset
   * @param implementation The address of the new implementation
   */
  error UntrustedImplementation(address implementation);

  /**
   * @notice Error returned when the plugin is reset
   * @param oldVersion The version of the current implementation
   * @param newVersion The version of the new implementation
   */
  error InvalidVersion(uint256 oldVersion, uint256 newVersion);

  /**
   * @notice Error returned when the plugin must be reset before using it
   */
  error PluginMustBeReset();

  /**
   * @notice Initialize the plugin. It must be implemented, but can do nothing is no init is needed.
   */
  function init(bytes memory data) external;

  /**
   * @notice Called by the manager during the plugging to know if the plugin is asking the
   * right to make a managed transfer of the vault
   */
  function requiresToManageTransfer() external pure returns (bool);

  /**
   * @notice Called by the manager to know it the plugin must be reset when transferring the NFT
   */
  function requiresResetOnTransfer() external pure returns (bool);

  /**
   * @notice Returns the minimum version of the manager required by the plugin
   */
  function requiredManagerVersion() external pure returns (uint256);

  /**
   * @notice Called by the manager to know if the plugin is an ERC721 account
   */
  function isERC6551Account() external pure returns (bool);

  /**
   * @notice Reset the plugin to the factory settings
   */
  function resetService() external payable;

  // @dev During transfer, to reduce gas consumption, should set _conf.mustBeReset to 1
  function resetOnTransfer() external payable;

  /**
   * @notice Returns the manager
   */
  function crunaManager() external view returns (CrunaManager);
}
