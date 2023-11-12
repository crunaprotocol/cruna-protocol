// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountGuardian} from "@tokenbound/contracts/AccountGuardian.sol";
import {Versioned} from "../utils/Versioned.sol";

contract Guardian is AccountGuardian, Versioned {
  constructor(address owner) AccountGuardian(owner) {}
}
