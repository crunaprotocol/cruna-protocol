// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {CrunaManager} from "../manager/CrunaManager.sol";
import {TokenLinkedContract} from "../utils/TokenLinkedContract.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {ICrunaPlugin, IVault} from "./ICrunaPlugin.sol";
import {CanonicalAddresses} from "../utils/CanonicalAddresses.sol";

//import {console} from "hardhat/console.sol";

abstract contract CrunaPluginBase is Context, CanonicalAddresses, TokenLinkedContract, IVersioned, ICrunaPlugin {
  error NotTheTokenOwner();
  error UntrustedImplementation();
  error InvalidVersion();
  error PluginRequiresUpdatedManager(uint256 requiredVersion);
  error ControllerAlreadySet();
  error NotTheDeployer();
  error Forbidden();

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  CrunaManager public manager;

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  // Inits the manager. It should be executed immediately after the deployment
  function initManager() external virtual override {
    if (address(manager) != address(0)) revert Forbidden();
    manager = CrunaManager(IVault(tokenAddress()).managerOf(tokenId()));
  }

  function isERC6551Account() external pure virtual returns (bool) {
    // override if an account
    return false;
  }

  function version() public pure virtual override returns (uint256) {
    return 1e6;
  }

  function nameId() public view virtual override returns (bytes4);

  function vault() public view virtual override returns (IVault) {
    return IVault(tokenAddress());
  }

  // @dev Upgrade the implementation of the plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    uint256 requires = _CRUNA_GUARDIAN.trustedImplementation(nameId(), implementation_);
    if (requires == 0) revert UntrustedImplementation();
    IVersioned impl = IVersioned(implementation_);
    uint256 _version = impl.version();
    if (_version <= version()) revert InvalidVersion();
    CrunaManager _manager = CrunaManager(vault().managerOf(tokenId()));
    if (_manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
