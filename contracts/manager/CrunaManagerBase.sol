// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICrunaManager} from "./ICrunaManager.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {Canonical} from "../libs/Canonical.sol";
import {INamedAndVersioned} from "../utils/INamedAndVersioned.sol";

/**
 * @title CrunaManagerBase.sol
 * @notice Base contract for managers and plugins
 */
abstract contract CrunaManagerBase is ICrunaManager, CommonBase, ReentrancyGuard {
  /**
   * @notice Upgrade the implementation of the manager
   * @param implementation_ The new implementation
   */
  function upgrade(address implementation_) external virtual override nonReentrant {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    if (!Canonical.crunaGuardian().trustedImplementation(bytes4(keccak256("CrunaManager")), implementation_))
      revert UntrustedImplementation(implementation_);
    INamedAndVersioned impl = INamedAndVersioned(implementation_);
    uint256 currentVersion = _version();
    uint256 newVersion = impl.version();
    if (newVersion <= _version()) revert InvalidVersion(_version(), newVersion);
    if (impl.nameId() != _stringToBytes4("CrunaManager")) revert NotAManager(_msgSender());
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    emit ImplementationUpgraded(implementation_, currentVersion, newVersion);
    CrunaManagerBase _newManager = CrunaManagerBase(address(this));
    _newManager.migrate(currentVersion);
  }

  /**
   * @notice Execute actions needed in a new manager based on the previous version
   * @param previousVersion The previous version
   */
  function migrate(uint256 previousVersion) external virtual;

  // @notice Returns the version of the manager
  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  // @notice This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
