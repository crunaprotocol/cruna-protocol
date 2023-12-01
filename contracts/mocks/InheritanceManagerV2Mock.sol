// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InheritanceManager} from "../plugins/InheritanceManager.sol";

contract InheritanceManagerV2Mock is InheritanceManager {
  function version() external pure virtual override returns (string memory) {
    return "2.0.0";
  }

  // new function in V2
  function isMock() external pure returns (bool) {
    return true;
  }
}
