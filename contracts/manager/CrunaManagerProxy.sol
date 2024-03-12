// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC6551AccountProxy} from "../utils/ERC6551AccountProxy.sol";

/**
  @title CrunaManagerProxy
  @dev Proxy contract for the CrunaManager
*/
contract CrunaManagerProxy is ERC6551AccountProxy {
  /**
    @dev Constructor
    @param _initialImplementation Address of the initial implementation
  */
  constructor(address _initialImplementation) ERC6551AccountProxy(_initialImplementation) {}
}
