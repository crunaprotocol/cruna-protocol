// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

contract Versioned {
  function version() external view virtual returns (string memory) {
    return "1.0.0";
  }
}
