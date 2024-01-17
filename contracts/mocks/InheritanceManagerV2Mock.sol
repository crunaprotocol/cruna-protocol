// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrunaInheritancePlugin} from "../plugins/inheritance/CrunaInheritancePlugin.sol";

contract InheritancePluginV2Mock is CrunaInheritancePlugin {
  uint256 public constant SOME_VARIABLE = 3;

  function version() public pure virtual override returns (uint256) {
    return 1000002;
  }
}
