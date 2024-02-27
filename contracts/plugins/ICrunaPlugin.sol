// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import {ITokenLinkedContract} from "../utils/ITokenLinkedContract.sol";
import {CrunaProtectedNFTBase} from "../token/CrunaProtectedNFTBase.sol";
import {INamed} from "../utils/INamed.sol";

/**
 @title ICrunaPlugin.sol
 @dev Interface for plugins
   Technically, plugins are secondary managers, pluggable in
   the primary manage, which is CrunaManager.sol
*/
interface ICrunaPlugin is ITokenLinkedContract, INamed {
  function initManager() external;

  // function called in the dashboard to know if the plugin is asking the
  // right to make a managed transfer of the vault
  function requiresToManageTransfer() external pure returns (bool);

  function requiresResetOnTransfer() external pure returns (bool);

  function isERC6551Account() external pure returns (bool);

  // Reset the plugin to the factory settings
  function reset() external;

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external;

  function vault() external view returns (CrunaProtectedNFTBase);
}
