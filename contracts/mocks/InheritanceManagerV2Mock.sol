// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InheritancePlugin} from "../plugins/inheritance/InheritancePlugin.sol";

contract InheritancePluginV2Mock is InheritancePlugin {
  function version() external pure virtual override returns (string memory) {
    return "2.0.0";
  }

  // new function in V2
  function isMock() external pure returns (bool) {
    return true;
  }
}
