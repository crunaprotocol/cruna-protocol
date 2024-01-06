// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

interface IVersioned {
  function version() external view returns (uint256);
}
