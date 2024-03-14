// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

/// @title IVersioned
/// @author Francesco Sullo <francesco@sullo.co>
interface IVersioned {
  /**
   * @dev Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   */
  function version() external view returns (uint256);
}
