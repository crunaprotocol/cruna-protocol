// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountProxy} from "erc6551/examples/upgradeable/ERC6551AccountProxy.sol";
import {Versioned} from "../utils/Versioned.sol";

contract ManagerProxy is ERC6551AccountProxy, Versioned {
  constructor(address _initialImplementation) ERC6551AccountProxy(_initialImplementation) {}
}
