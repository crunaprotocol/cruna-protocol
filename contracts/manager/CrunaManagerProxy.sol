// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountProxy} from "../utils/ERC6551AccountProxy.sol";

contract CrunaManagerProxy is ERC6551AccountProxy {
  constructor(address _initialImplementation) ERC6551AccountProxy(_initialImplementation) {}
}
