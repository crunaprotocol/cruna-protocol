// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IPlugin {
  function init() external;

  function pluginRoles() external view returns (bytes32[] memory);

  // function called in the dashboard to know if the plugin is asking the
  // right to make a managed transfer of the vault
  function requiresToManageTransfer() external pure returns (bool);

  // Reset the plugin to the factory settings
  function reset() external;
}
