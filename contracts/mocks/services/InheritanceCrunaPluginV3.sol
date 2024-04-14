// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {InheritanceCrunaPlugin} from "../../services/inheritance/InheritanceCrunaPlugin.sol";

contract InheritanceCrunaPluginV3 is InheritanceCrunaPlugin {
  uint256 public constant SOME_VARIABLE = 3;
  bool public constant SOME_OTHER_VARIABLE = true;

  function _version() internal pure virtual override returns (uint256) {
    return 1_001_003;
  }

  // new function in V3
  function isMock() external pure returns (bool) {
    return true;
  }
}
