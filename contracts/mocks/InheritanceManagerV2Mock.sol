// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InheritanceCrunaPlugin} from "../plugins/inheritance/InheritanceCrunaPlugin.sol";

contract InheritancePluginV2Mock is InheritanceCrunaPlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function version() public pure virtual override returns (uint256) {
    return 1000002;
  }
}
