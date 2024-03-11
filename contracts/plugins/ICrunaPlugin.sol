// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.20;

import {ITokenLinkedContract} from "../utils/ITokenLinkedContract.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {CrunaManager} from "../manager/CrunaManager.sol";

/**
 @title ICrunaPlugin.sol
 @dev Interface for plugins
   Technically, plugins are secondary managers, pluggable in
   the primary manage, which is CrunaManager.sol
*/
interface ICrunaPlugin is ITokenLinkedContract, IVersioned {
  struct Conf {
    CrunaManager manager;
    // When mustReset is true, the plugin must be reset before being used again.
    // This strategy is needed during transfers to avoid gas issues, because actually resetting the
    // data can be expensive. As a trade-off, the receiver of the protected NFT must reset the plugin.
    uint32 mustBeReset;
  }

  error UntrustedImplementation(address implementation);
  error InvalidVersion(uint256 version);
  error PluginRequiresUpdatedManager(uint256 requiredVersion);
  error Forbidden();
  error PluginMustBeReset();

  function init() external;

  // function called in the dashboard to know if the plugin is asking the
  // right to make a managed transfer of the vault
  function requiresToManageTransfer() external pure returns (bool);

  function requiresResetOnTransfer() external pure returns (bool);

  function isERC6551Account() external pure returns (bool);

  // Reset the plugin to the factory settings
  function reset() external;

  // here is were _conf.mustBeReset is set to 1
  function resetOnTransfer() external;

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external;

  function manager() external view returns (CrunaManager);
}
