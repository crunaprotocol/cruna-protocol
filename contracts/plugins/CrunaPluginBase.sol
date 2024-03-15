// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaPlugin, IVersioned} from "./ICrunaPlugin.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {Canonical} from "../libs/Canonical.sol";

/**
 * @title CrunaPluginBase
 * @notice Base contract for plugins
 */
abstract contract CrunaPluginBase is ICrunaPlugin, CommonBase, ReentrancyGuard {
  /**
   * @notice The internal configuration of the plugin
   */
  Conf internal _conf;

  /**
   * @notice Verifies that the plugin must not be reset
   */
  modifier ifMustNotBeReset() {
    if (_conf.mustBeReset == 1) revert PluginMustBeReset();
    _;
  }

  /// @dev see {ICrunaPlugin-init}
  function init() external {
    address managerAddress = _vault().managerOf(tokenId());
    if (_msgSender() != managerAddress) revert Forbidden();
    _conf.manager = CrunaManager(managerAddress);
  }

  /// @dev see {ICrunaPlugin-manager}
  function manager() external view virtual override returns (CrunaManager) {
    return _conf.manager;
  }

  /// @dev see {IVersioned-version}
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  /// @dev see {ICrunaPlugin-upgrade}
  function upgrade(address implementation_) external virtual override nonReentrant {
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
    if (version_ <= _version()) revert InvalidVersion(_version(), version_);
    if (_conf.manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  /// @dev see {ICrunaPlugin-resetOnTransfer}
  // The manager is not a wallet, it is the NFT Manager contract, owned by the token.
  function resetOnTransfer() external override ifMustNotBeReset {
    if (_msgSender() != address(_conf.manager)) revert Forbidden();
    _conf.mustBeReset = 1;
  }

  /**
   * @notice Internal function to verify if a signer can pre approve an operation (if the sender is a protector)
   * The params:
   * - operation The selector of the called function
   * - the actor to be approved
   * - signer The signer of the operation (the protector)
   */
  function _canPreApprove(bytes4, address, address signer) internal view virtual override returns (bool) {
    return _conf.manager.isProtector(signer);
  }

  /// @dev see {IVersioned-version}
  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  /**
   * @notice internal function to check if the NFT is currently protected
   */
  function _isProtected() internal view virtual override returns (bool) {
    return _conf.manager.hasProtectors();
  }

  /**
   * @notice Internal function to check if an address is a protector
   * @param protector The address to check
   */
  function _isProtector(address protector) internal view virtual override returns (bool) {
    return _conf.manager.isProtector(protector);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
