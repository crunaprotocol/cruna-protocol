// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

// ERC165 interfaceId 0x6b61a747
interface IPlugin {
  function init(address guardian_, address signatureValidator_) external;

  function pluginRoles() external view returns (bytes32[] memory);
}
