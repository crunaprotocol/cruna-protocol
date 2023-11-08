// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountGuardian} from "@tokenbound/contracts/AccountGuardian.sol";

contract ManagerGuardian is AccountGuardian {
  constructor(address owner) AccountGuardian(owner) {}
}
