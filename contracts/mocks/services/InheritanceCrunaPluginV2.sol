// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InheritanceCrunaPlugin, ICrunaManagedService, CrunaManagedService} from "../../services/inheritance/InheritanceCrunaPlugin.sol";

contract InheritanceCrunaPluginV2 is InheritanceCrunaPlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function _version() internal pure virtual override returns (uint256) {
    return 1_001_002;
  }

  function requiredManagerVersion() external pure override(CrunaManagedService, ICrunaManagedService) returns (uint256) {
    return 1_002_000;
  }
}
