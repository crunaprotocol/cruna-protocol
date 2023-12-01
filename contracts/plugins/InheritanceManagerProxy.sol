// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ManagerProxy} from "../manager/ManagerProxy.sol";

contract InheritanceManagerProxy is ManagerProxy {
  constructor(address _initialImplementation) ManagerProxy(_initialImplementation) {}
}
