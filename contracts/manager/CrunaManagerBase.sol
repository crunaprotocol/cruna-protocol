// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

import {TokenLinkedContract} from "../utils/TokenLinkedContract.sol";
import {INamed} from "../utils/INamed.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {CrunaProtectedNFT} from "../token/CrunaProtectedNFT.sol";
import {ICrunaManager} from "./ICrunaManager.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {CanonicalAddresses} from "../canonical/CanonicalAddresses.sol";

//import {console} from "hardhat/console.sol";

interface INamedAndVersioned is INamed, IVersioned {}

/**
  @title CrunaManagerBase.sol
  @dev Base contract for managers and plugins
*/
abstract contract CrunaManagerBase is
  Context,
  CanonicalAddresses,
  TokenLinkedContract,
  IVersioned,
  ICrunaManager,
  SignatureValidator
{
  error NotTheTokenOwner();
  error UntrustedImplementation();
  error InvalidVersion();
  error PluginRequiresUpdatedManager(uint256 requiredVersion);
  error ControllerAlreadySet();
  error NotTheDeployer();
  error Forbidden();
  error NotAManager();

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  function version() public pure virtual override returns (uint256) {
    return 1e6;
  }

  modifier onlyTokenOwner() {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  function vault() public view virtual override returns (CrunaProtectedNFT) {
    return CrunaProtectedNFT(tokenAddress());
  }

  function nameId() public view virtual override returns (bytes4) {
    return _stringToBytes4("CrunaManager");
  }

  function _stringToBytes4(string memory str) internal pure returns (bytes4) {
    return bytes4(keccak256(abi.encodePacked(str)));
  }

  // @dev Upgrade the implementation of the manager
  function upgrade(address implementation_) external virtual override {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    uint256 requires = _crunaGuardian().trustedImplementation(nameId(), implementation_);
    if (requires == 0) revert UntrustedImplementation();
    INamedAndVersioned impl = INamedAndVersioned(implementation_);
    uint256 currentVersion = version();
    uint256 newVersion = impl.version();
    if (newVersion <= version()) revert InvalidVersion();
    if (impl.nameId() != _stringToBytes4("CrunaManager")) revert NotAManager();
    INamedAndVersioned manager = INamedAndVersioned(vault().managerOf(tokenId()));
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
