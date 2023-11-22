// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountGuardian} from "@tokenbound/contracts/AccountGuardian.sol";
import {Versioned} from "../utils/Versioned.sol";

// @dev This contract is a guardian for manager implementations.
//   It avoid that a user upgrade a manager implementation to a malicious version.
contract Guardian is AccountGuardian, Versioned {
  constructor(address owner) AccountGuardian(owner) {}
}
