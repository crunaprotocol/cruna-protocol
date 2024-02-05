// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {CrunaManager} from "../manager/CrunaManager.sol";
import {IBoundContract} from "../utils/IBoundContract.sol";
import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {ICrunaPlugin, IVault} from "./ICrunaPlugin.sol";
import {WithDeployer} from "../utils/WithDeployer.sol";
import {IControlled} from "../utils/IControlled.sol";

//import {console} from "hardhat/console.sol";

abstract contract CrunaPluginBase is Context, IBoundContract, IVersioned, ICrunaPlugin, IControlled {
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

  address private _deployer;
  mapping(bytes32 => bool) public usedSignatures;
  CrunaManager public manager;

  // the controller is the vault inside the manager proxy (i.e., the event emitter),
  // not inside the manager of the single tokenId
  IVault internal _controller;

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  constructor() {
    //    currentVersion = version();
  }

  function controller() public view virtual override returns (address) {
    return address(_controller);
  }

  function setController(address controller_) external override {
    WithDeployer proxy = WithDeployer(address(this));
    if (proxy.deployer() != _msgSender()) revert NotTheDeployer();
    if (address(_controller) != address(0)) revert ControllerAlreadySet();
    _controller = IVault(controller_);
  }

  function version() public pure virtual override returns (uint256) {
    return 1e6;
  }

  function nameId() public view virtual override returns (bytes4);

  function guardian() public view virtual override returns (ICrunaGuardian) {
    return manager.guardian();
  }

  function vault() public view virtual override returns (IVault) {
    return manager.vault();
  }

  function emitter() public view virtual override returns (address) {
    return manager.pluginEmitter(nameId());
  }

  function token() public view virtual override returns (uint256, address, uint256) {
    return ERC6551AccountLib.token();
  }

  function owner() public view virtual override returns (address) {
    (uint256 chainId, address tokenContract_, uint256 tokenId_) = token();
    if (chainId != block.chainid) return address(0);
    return IERC721(tokenContract_).ownerOf(tokenId_);
  }

  function tokenAddress() public view virtual override returns (address) {
    (, address tokenContract_, ) = token();
    return tokenContract_;
  }

  function tokenId() public view virtual override returns (uint256) {
    (, , uint256 tokenId_) = token();
    return tokenId_;
  }

  // @dev Upgrade the implementation of the manager/plugin
  //   Notice that the owner can upgrade active or disable plugins
  //   so that, if a plugin is compromised, the user can disable it,
  //   wait for a new trusted implementation and upgrade it.
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    uint256 requires = guardian().trustedImplementation(nameId(), implementation_);
    if (requires == 0) revert UntrustedImplementation();
    CrunaManager impl = CrunaManager(implementation_);
    uint256 _version = impl.version();
    if (_version <= version()) revert InvalidVersion();
    CrunaManager _manager = CrunaManager(vault().managerOf(tokenId()));
    if (_manager.version() < requires) revert PluginRequiresUpdatedManager(requires);
    StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = implementation_;
    manager.updateEmitterForPlugin(nameId(), implementation_);
  }

  function getImplementation() external view override returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
