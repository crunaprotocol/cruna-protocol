// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Manager} from "../manager/Manager.sol";

contract ManagerV2Mock is Manager {
  function version() external view virtual override returns (string memory) {
    return "2.0.0";
  }
}
