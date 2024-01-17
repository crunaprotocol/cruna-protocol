// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CrunaProxy} from "../../utils/CrunaProxy.sol";

contract CrunaInheritancePluginProxy is CrunaProxy {
  constructor(address _initialImplementation) CrunaProxy(_initialImplementation) {
    proxyName = keccak256("CrunaInheritancePluginProxy");
  }
}
