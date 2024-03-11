// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaPlugin, IVersioned} from "./ICrunaPlugin.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {Canonical} from "../libs/Canonical.sol";

// import {console} from "hardhat/console.sol";

abstract contract CrunaPluginBase is ICrunaPlugin, CommonBase {
  Conf internal _conf;

  modifier ifMustNotBeReset() {
    if (_conf.mustBeReset == 1) revert PluginMustBeReset();
    _;
  }

  modifier onlyManager() {
    if (_msgSender() != address(_conf.manager)) revert Forbidden();
    _;
  }

  function init() external {
    address managerAddress = _vault().managerOf(tokenId());
    if (_msgSender() != managerAddress) revert Forbidden();
    _conf.manager = CrunaManager(managerAddress);
  }

  function manager() external view virtual override returns (CrunaManager) {
    return _conf.manager;
  }

  function isERC6551Account() external pure virtual returns (bool) {
    // override if an account
    return false;
  }

  // override if function is not 1.0.0
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  // @dev Upgrade the implementation of the plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    uint256 requires = Canonical.crunaGuardian().trustedImplementation(_nameId(), implementation_);
    if (0 == requires) {
      // The new implementation is not trusted.
      // If current implementation is trusted, the new implementation must be trusted too
      if (Canonical.crunaGuardian().trustedImplementation(_nameId(), implementation()) != 0)
        revert UntrustedImplementation(implementation_);
    }
    IVersioned impl = IVersioned(implementation_);
    uint256 version_ = impl.version();
    if (version_ <= _version()) revert InvalidVersion(version_);
    if (_conf.manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  /// @dev This sets the plugin as must be reset. It is the plugin's responsibility
  /// to set itself as market for reset and act consequently.
  function resetOnTransfer() external override ifMustNotBeReset onlyManager {
    _conf.mustBeReset = 1;
  }

  function _canPreApprove(bytes4, address, address signer) internal view virtual override returns (bool) {
    return _conf.manager.isProtector(signer);
  }

  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
