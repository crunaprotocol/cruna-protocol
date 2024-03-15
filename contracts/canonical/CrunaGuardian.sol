// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {FlexiTimelockController} from "../utils/FlexiTimelockController.sol";

/**
 * @title CrunaGuardian
 * @notice Manages a registry of trusted implementations and their required manager versions
 *
 * It is used by
 * - manager and plugins to upgrade its own  implementation
 * - manager to trust a new plugin implementation and allow managed transfers
 */
contract CrunaGuardian is ICrunaGuardian, IVersioned, FlexiTimelockController {
  /**
   * @notice Error returned when the arguments are invalid
   */
  error InvalidArguments();

  /**
   * @notice Emitted when a trusted implementation is updated
   */
  mapping(bytes32 nameIdAndImplementationAddress => uint256 requiredManagerVersion) private _trustedImplementations;

  /**
   * @notice When deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO
   * @param minDelay The minimum delay for timelock operations
   * @param proposers The addresses that can propose timelock operations
   * @param executors The addresses that can execute timelock operations
   * @param admin The address that can admin the contract. It will renounce to the role, as soon as the
   *  DAO is stable and there are no risks in doing so.
   */
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) FlexiTimelockController(minDelay, proposers, executors, admin) {}

  /**
   * @notice see {ICrunaGuardian-setTrustedImplementation}
   */
  function version() external pure virtual returns (uint256) {
    // v1.1.0
    return 1_001_000;
  }

  // @notice see {ICrunaGuardian.sol-setTrustedImplementation}
  function setTrustedImplementation(
    bytes4 nameId,
    address implementation,
    bool trusted,
    uint256 requires
  ) external override onlyThroughTimeController {
    if (requires == 0 || implementation == address(0)) {
      revert InvalidArguments();
    }
    bytes32 _key = bytes32(nameId) | bytes32(uint256(uint160(implementation)));
    if (trusted) {
      _trustedImplementations[_key] = requires;
    } else {
      delete _trustedImplementations[_key];
    }
    emit TrustedImplementationUpdated(nameId, implementation, trusted, requires);
  }

  function trustedImplementation(bytes4 nameId, address implementation) external view override returns (uint256) {
    return _trustedImplementations[bytes32(nameId) | bytes32(uint256(uint160(implementation)))];
  }
}
