// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {ICrunaManager} from "./ICrunaManager.sol";
import {CommonBase} from "../utils/CommonBase.sol";

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
  function nameId() public view virtual override returns (bytes4) {
    // In this case, we do not use _hashString because the keccak256 is calculated at compile time
    return bytes4(keccak256("CrunaManager"));
  }

  function version() public pure virtual override returns (uint256) {
    return 1_000_000;
  }

  // @dev Upgrade the implementation of the manager
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    uint256 requires = _crunaGuardian().trustedImplementation(nameId(), implementation_);
    if (0 == requires) revert UntrustedImplementation();
    INamedAndVersioned impl = INamedAndVersioned(implementation_);
    uint256 currentVersion = version();
    uint256 newVersion = impl.version();
    if (newVersion <= version()) revert InvalidVersion();
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

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
