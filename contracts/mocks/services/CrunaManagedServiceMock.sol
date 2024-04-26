// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CrunaManagedService} from "../../services/CrunaManagedService.sol";

contract CrunaManagedServiceMock is CrunaManagedService {
  function _nameId() internal pure virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaManagedServiceMock"));
  }
}
