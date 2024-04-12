// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaManagedService} from "./ICrunaManagedService.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {Actor} from "../manager/Actor.sol";
//import "hardhat/console.sol";

/**
 * @title CrunaManagedService
 * @notice Base contract for services
 */
abstract contract CrunaManagedService is ICrunaManagedService, Actor, CommonBase, SignatureValidator {
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

  function _onBeforeInit() internal virtual {
    // does nothing
  }

  /// @dev see {ICrunaManagedService.sol-init}
  function init() external {
    address managerAddress = _vault().managerOf(tokenId());
    if (_msgSender() != managerAddress) revert Forbidden();
    _onBeforeInit();
    _conf.manager = CrunaManager(managerAddress);
  }

  /// @dev see {ICrunaManagedService.sol-manager}
  function manager() external view virtual override returns (CrunaManager) {
    return _conf.manager;
  }

  /// @dev see {IVersioned-version}
  function version() external pure virtual override returns (uint256) {
    return _version();
  }

  /// @dev see {ICrunaManagedService.sol-resetOnTransfer}
  function resetOnTransfer() external payable override ifMustNotBeReset {
    /**
     * @notice The manager is not a wallet, it is the NFT Manager contract, owned by the token.
     * Making it payable reduce the gas cost for the manager to call this function.
     */
    if (_msgSender() != address(_conf.manager)) revert Forbidden();
    _conf.mustBeReset = 1;
  }

  /// @dev see {ICrunaManagedService.sol-requiresToManageTransfer}
  function requiresToManageTransfer() external pure virtual override returns (bool) {
    return false;
  }

  /// @dev see {ICrunaManagedService.sol-requiresResetOnTransfer}
  function requiresResetOnTransfer() external pure virtual override returns (bool) {
    return false;
  }

  /// @dev see {ICrunaManagedService.sol-requiresManagerVersion}
  function requiresManagerVersion() external pure virtual override returns (uint256) {
    return 1;
  }

  /// @dev see {ICrunaManagedService.sol-isERC6551Account}
  function isERC6551Account() external pure virtual returns (bool) {
    return false;
  }

  function isManaged() external pure returns (bool) {
    return true;
  }

  function reset() external payable virtual override {
    // doing nothing
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
  function _isProtected() internal view override returns (bool) {
    return _conf.manager.hasProtectors();
  }

  /**
   * @notice Internal function to check if an address is a protector
   * @param protector The address to check
   */
  function _isProtector(address protector) internal view override returns (bool) {
    return _conf.manager.isProtector(protector);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
