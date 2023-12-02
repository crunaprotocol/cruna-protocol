// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Manager} from "../manager/Manager.sol";

contract ManagerV2Mock is Manager {
  function version() public pure virtual override returns (uint256) {
    return 2;
  }

  // new function in V2
  function isMock() external pure returns (bool) {
    return true;
  }
}
