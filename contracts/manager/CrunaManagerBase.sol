// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {ICrunaManager} from "./ICrunaManager.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {Canonical} from "../libs/Canonical.sol";

// import {console} from "hardhat/console.sol";

interface INamedAndVersioned {
  function nameId() external view returns (bytes4);
  function version() external view returns (uint256);
}

/**
  @title CrunaManagerBase.sol
  @dev Base contract for managers and plugins
*/
abstract contract CrunaManagerBase is ICrunaManager, CommonBase {
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  // @dev Upgrade the implementation of the manager
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    uint256 requires = Canonical.crunaGuardian().trustedImplementation(bytes4(keccak256("CrunaManager")), implementation_);
    if (0 == requires) revert UntrustedImplementation();
    INamedAndVersioned impl = INamedAndVersioned(implementation_);
    uint256 currentVersion = _version();
    uint256 newVersion = impl.version();
    if (newVersion <= _version()) revert InvalidVersion();
    if (impl.nameId() != _stringToBytes4("CrunaManager")) revert NotAManager();
    INamedAndVersioned manager = INamedAndVersioned(_vault().managerOf(tokenId()));
    if (manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    emit ImplementationUpgraded(implementation_, currentVersion, newVersion);
    CrunaManagerBase _newManager = CrunaManagerBase(address(this));
    _newManager.migrate(currentVersion);
  }

  // must be implemented by the manager
  function migrate(uint256 previousVersion) external virtual;

  function _nameId() internal view virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaManager"));
  }

  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
