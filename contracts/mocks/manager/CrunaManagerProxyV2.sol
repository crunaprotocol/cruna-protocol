// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC6551AccountProxy} from "../../erc/ERC6551AccountProxy.sol";

contract CrunaManagerProxyV2 is ERC6551AccountProxy {
  constructor(address _initialImplementation) ERC6551AccountProxy(_initialImplementation) {}

  function getImplementation() external view returns (address) {
    return _implementation();
  }
}
