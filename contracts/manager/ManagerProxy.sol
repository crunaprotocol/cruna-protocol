// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountProxy} from "@tokenbound/contracts/AccountProxy.sol";
import {Versioned} from "../utils/Versioned.sol";

contract ManagerProxy is AccountProxy, Versioned {
  constructor(address _guardian, address _initialImplementation) AccountProxy(_guardian, _initialImplementation) {}
}
