// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FlexiProxy} from "../../../utils/FlexiProxy.sol";

contract SomePluginProxy is FlexiProxy {
  constructor(address _initialImplementation) FlexiProxy(_initialImplementation) {}
}
