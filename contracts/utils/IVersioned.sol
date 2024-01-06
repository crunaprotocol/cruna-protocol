// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.0;

interface IVersioned {
  // @dev It returns the version of the contract
  //   It use a semantic version, where
  //     1.2.3 => 1e6 + 2e3 + 3 => 1002003
  function version() external view returns (uint256);
}
