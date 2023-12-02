// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// @dev This contract supports versions.
contract Versioned {
  // @dev This function will return the version of the contract.
  // @return The version of the contract as a string.
  function version() public pure virtual returns (uint256) {
    return 1;
  }
}
