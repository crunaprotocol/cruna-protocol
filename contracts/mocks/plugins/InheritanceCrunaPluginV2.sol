// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InheritanceCrunaPlugin, ICrunaPlugin, CrunaPluginBase} from "../../plugins/inheritance/InheritanceCrunaPlugin.sol";

contract InheritanceCrunaPluginV2 is InheritanceCrunaPlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function _version() internal pure virtual override returns (uint256) {
    return 1_001_002;
  }

  function requiresManagerVersion() external pure override(CrunaPluginBase, ICrunaPlugin) returns (uint256) {
    return 1_002_000;
  }
}
