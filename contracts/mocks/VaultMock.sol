// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrunaFlexiVault} from "../CrunaFlexiVault.sol";
import {IManagedERC721} from "../interfaces/IManagedERC721.sol";

contract VaultMock is CrunaFlexiVault {
  constructor(address owner) CrunaFlexiVault(owner) {}

  function getIProtectedInterfaceId() external pure returns (bytes4) {
    return type(IManagedERC721).interfaceId;
  }
}
