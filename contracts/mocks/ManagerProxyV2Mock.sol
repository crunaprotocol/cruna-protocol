// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC6551AccountProxy} from "../utils/ERC6551AccountProxy.sol";

contract ManagerProxyV2Mock is ERC6551AccountProxy {
  constructor(address _initialImplementation, address _deployer) ERC6551AccountProxy(_initialImplementation, _deployer) {}

  function getImplementation() external view returns (address) {
    return _implementation();
  }
}
