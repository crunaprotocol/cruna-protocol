// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaPlugin, IVersioned} from "./ICrunaPlugin.sol";
import {CommonBase} from "../utils/CommonBase.sol";

// import {console} from "hardhat/console.sol";

abstract contract CrunaPluginBase is ICrunaPlugin, CommonBase {
  function manager() external view virtual override returns (CrunaManager) {
    return _manager();
  }

  function isERC6551Account() external pure virtual returns (bool) {
    // override if an account
    return false;
  }

  function version() public pure virtual override returns (uint256) {
    return 1_000_000;
  }

  // @dev Upgrade the implementation of the plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    uint256 requires = _crunaGuardian().trustedImplementation(nameId(), implementation_);
    if (0 == requires) {
      // The new implementation is not trusted.
      // If current implementation is trusted, the new implementation must be trusted too
      if (_crunaGuardian().trustedImplementation(nameId(), implementation()) != 0) revert UntrustedImplementation();
    }
    IVersioned impl = IVersioned(implementation_);
    uint256 _version = impl.version();
    if (_version <= version()) revert InvalidVersion();
    if (_manager().version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  function _canPreApprove(bytes4, address, address signer) internal view virtual override returns (bool) {
    return _manager().isAProtector(signer);
  }

  function _manager() internal view virtual returns (CrunaManager) {
    return CrunaManager(_vault().managerOf(tokenId()));
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
