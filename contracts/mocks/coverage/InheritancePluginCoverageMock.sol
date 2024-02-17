// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InheritanceCrunaPlugin} from "../../plugins/inheritance/InheritanceCrunaPlugin.sol";

import {ICrunaGuardian, ICrunaRegistry, IERC6551Registry} from "../../utils/CanonicalAddresses.sol";

contract InheritancePluginCoverageMock is InheritanceCrunaPlugin {
  ICrunaGuardian internal _guardianMock;

  ICrunaRegistry internal _registryMock;

  IERC6551Registry internal _erc6551registryMock;

  function setFakeConstants(address registry_, address erc6551Registry_, address guardian_) external {
    _guardianMock = ICrunaGuardian(guardian_);
    _registryMock = ICrunaRegistry(registry_);
    _erc6551registryMock = IERC6551Registry(erc6551Registry_);
  }

  function _crunaRegistry() internal view override returns (ICrunaRegistry) {
    return _registryMock;
  }

  function _erc6551Registry() internal view override returns (IERC6551Registry) {
    return _erc6551registryMock;
  }

  function _crunaGuardian() internal view override returns (ICrunaGuardian) {
    return _guardianMock;
  }
}
