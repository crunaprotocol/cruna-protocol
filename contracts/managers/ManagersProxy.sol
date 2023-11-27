// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountProxy} from "erc6551/examples/upgradeable/ERC6551AccountProxy.sol";

// @dev This contract is a proxy for managers implementations.
//   Look at ERC6551AccountProxy for more details.
contract ManagersProxy is ERC6551AccountProxy {
  constructor(address _initialImplementation) ERC6551AccountProxy(_initialImplementation) {}
}
