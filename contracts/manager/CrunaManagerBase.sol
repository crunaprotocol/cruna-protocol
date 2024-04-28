// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {ICrunaManager} from "./ICrunaManager.sol";
import {CommonBase} from "../utils/CommonBase.sol";
import {GuardianInstance} from "../libs/GuardianInstance.sol";
import {INamedAndVersioned} from "../utils/INamedAndVersioned.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {Actor} from "../manager/Actor.sol";
import {ManagerConstants} from "../libs/ManagerConstants.sol";

/**
 * @title CrunaManagerBase.sol
 * @notice Base contract for managers and services
 */
abstract contract CrunaManagerBase is ICrunaManager, GuardianInstance, CommonBase, Actor, SignatureValidator, ReentrancyGuard {
  /**
   * @notice Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @notice Upgrade the implementation of the manager
   * @param implementation_ The new implementation
   */
  function upgrade(address implementation_) external virtual override nonReentrant {
    if (owner() != _msgSender()) revert NotTheTokenOwner();
    if (implementation_ == address(0)) revert ZeroAddress();
    if (!_crunaGuardian().trustedImplementation(bytes4(keccak256("CrunaManager")), implementation_))
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

  /**
   * @notice Utility function to combine two bytes4 into a bytes8
   */
  function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8) {
    return bytes8(bytes32(a) | (bytes32(b) >> 32));
  }

  /**
   * @notice Check if the NFT is protected
   * Required by SignatureValidator
   */
  function _isProtected() internal view override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  /**
   * @notice Checks if an address is a protector
   * Required by SignatureValidator
   * @param protector_ The address to check
   */
  function _isProtector(address protector_) internal view override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  // @notice Returns the version of the manager
  function _version() internal pure virtual returns (uint256) {
    return 1_000_000;
  }

  /**
   * @notice Returns the keccak256 of a string variable.
   * It saves gas compared to keccak256(abi.encodePacked(string)).
   * @param input The string to hash
   */
  function _hashString(string memory input) internal pure returns (bytes32 result) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Load the pointer to the free memory slot
      let ptr := mload(0x40)
      // Copy data using Solidity's default encoding, which includes the length
      mstore(ptr, mload(add(input, 32)))
      // Calculate keccak256 hash
      result := keccak256(ptr, mload(input))
    }
  }

  /**
   * @notice Returns the equivalent of bytes4(keccak256(str).
   * @param str The string to hash
   */
  function _stringToBytes4(string memory str) internal pure returns (bytes4) {
    return bytes4(_hashString(str));
  }

  // @notice This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
