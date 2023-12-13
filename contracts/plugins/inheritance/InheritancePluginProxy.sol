// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FlexiProxy} from "../../utils/FlexiProxy.sol";

contract InheritancePluginProxy is FlexiProxy {
  bytes32 public proxyName;

  constructor(address _initialImplementation) FlexiProxy(_initialImplementation) {
    proxyName = keccak256("InheritancePluginProxy");
  }
}
