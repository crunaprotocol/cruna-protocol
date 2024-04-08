// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {CrunaManager} from "../manager/CrunaManager.sol";
import {ICrunaPlugin} from "./ICrunaPlugin.sol";
import {CommonBase} from "../utils/CommonBase.sol";

//import "hardhat/console.sol";


/**
 * @title CrunaPluginBase
 * @notice Base contract for plugins
 */
abstract contract CrunaPluginBase is ICrunaPlugin, CommonBase {
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

  /// @dev see {ICrunaPlugin-init}
  function init() external {
    address managerAddress = _vault().managerOf(tokenId());
    if (_msgSender() != managerAddress) revert Forbidden();
    _onBeforeInit();
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

  /// @dev see {ICrunaPlugin-resetOnTransfer}
  function resetOnTransfer() external override ifMustNotBeReset
   payable
  {
    /**
     * @notice The manager is not a wallet, it is the NFT Manager contract, owned by the token.
     * Making it payable reduce the gas cost for the manager to call this function.
     */
    if (_msgSender() != address(_conf.manager)) revert Forbidden();
    _conf.mustBeReset = 1;
  }

  /// @dev see {ICrunaPlugin-requiresToManageTransfer}
  function requiresToManageTransfer() external pure virtual override returns (bool) {
    return false;
  }

  /// @dev see {ICrunaPlugin-requiresManagerVersion}
  function requiresManagerVersion() external pure virtual override returns (uint256) {
    return 1;
  }

  /// @dev see {ICrunaPlugin-isERC6551Account}
  function isERC6551Account() external pure virtual returns (bool) {
    return false;
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
