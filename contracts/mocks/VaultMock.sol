// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CrunaFlexiVault} from "../CrunaFlexiVault.sol";
import {IProtected} from "../interfaces/IProtected.sol";

contract VaultMock is CrunaFlexiVault {
  constructor(
    address registry_,
    address guardian_,
    address signatureValidator_,
    address managerProxy_
  ) CrunaFlexiVault(registry_, guardian_, signatureValidator_, managerProxy_) {}

  function getIProtectedInterfaceId() external pure returns (bytes4) {
    return type(IProtected).interfaceId;
  }
}
