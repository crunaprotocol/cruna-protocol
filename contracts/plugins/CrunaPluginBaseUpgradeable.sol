// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICrunaPlugin, CrunaPluginBase} from "./CrunaPluginBase.sol";
import {Canonical} from "../libs/Canonical.sol";

/**
 * @title CrunaPluginBaseUpgradeable
 * @notice Base upgradeable contract for plugins
 */
abstract contract CrunaPluginBaseUpgradeable is CrunaPluginBase, ReentrancyGuard {
  /**
   * @notice Upgrades the implementation of the plugin
   * @param implementation_ The new implementation
   */
  function upgrade(address implementation_) external virtual nonReentrant {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    bool trusted = Canonical.crunaGuardian().trustedImplementation(_nameId(), implementation_);
    if (!trusted) {
      // If current implementation is trusted, the new implementation must be trusted too
      if (Canonical.crunaGuardian().trustedImplementation(_nameId(), implementation()))
        revert UntrustedImplementation(implementation_);
    }
    ICrunaPlugin impl = ICrunaPlugin(implementation_);
    uint256 version_ = impl.version();
    if (version_ <= _version()) revert InvalidVersion(_version(), version_);
    uint256 requiredVersion = impl.requiresManagerVersion();
    if (_conf.manager.version() < requiredVersion) revert PluginRequiresUpdatedManager(requiredVersion);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
