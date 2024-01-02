// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InheritancePlugin} from "../plugins/inheritance/InheritancePlugin.sol";

contract InheritancePluginV2Mock is InheritancePlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function version() public pure virtual override returns (uint256) {
    return 1000002;
  }
}
