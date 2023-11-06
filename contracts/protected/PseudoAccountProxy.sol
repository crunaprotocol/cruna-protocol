// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccountProxy} from "@tokenbound/contracts/AccountProxy.sol";

contract PseudoAccountProxy is AccountProxy {
  constructor(address _guardian, address _initialImplementation) AccountProxy(_guardian, _initialImplementation) {}
}
