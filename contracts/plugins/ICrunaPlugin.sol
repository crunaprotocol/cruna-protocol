// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

/**
 @title ICrunaPlugin.sol
 @dev Interface for plugins
   Technically, plugins are secondary managers, pluggable in
   the primary manage, which is CrunaManager.sol.sol
*/
interface ICrunaPlugin {
  // this is also used in the CrunaManager
  struct CrunaPlugin {
    address proxyAddress;
    bool canManageTransfer;
    bool canBeReset;
    bool active;
  }

  function init() external;

  // function called in the dashboard to know if the plugin is asking the
  // right to make a managed transfer of the vault
  function requiresToManageTransfer() external pure returns (bool);

  function requiresResetOnTransfer() external pure returns (bool);

  // Reset the plugin to the factory settings
  function reset() external;
}
