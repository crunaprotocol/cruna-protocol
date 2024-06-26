// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimeControlledGovernance} from "./TimeControlledGovernance.sol";

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";

//import "hardhat/console.sol";

/**
 * @title CrunaGuardian
 * @notice Manages a registry of trusted implementations and their required manager versions
 *
 * It is used by
 * - manager and services to upgrade its own  implementation
 * - manager to trust a new plugin implementation and allow managed transfers
 */
contract CrunaGuardian is ICrunaGuardian, IVersioned, TimeControlledGovernance {
  /**
   * @notice Error returned when the arguments are invalid
   */
  error InvalidArguments();

  mapping(address implementation => bool trusted) private _trusted;

  /**
   * @notice When deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO
   * @param minDelay The minimum delay for time lock operations
   * @param firstProposer The address that can propose time lock operations
   * @param firstExecutor The address that can execute time lock operations
   * @param admin The address that can admin the contract.
   */
  constructor(
    uint256 minDelay,
    address firstProposer,
    address firstExecutor,
    address admin
  ) TimeControlledGovernance(minDelay, firstProposer, firstExecutor, admin) {}

  /**
   * @notice Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   */
  function version() external pure virtual returns (uint256) {
    // v1.1.0
    return 1_003_000;
  }

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param implementation The address of the implementation
   */
  function trust(uint256 delay, OperationType oType, address implementation, bool trusted_) external override {
    if (trusted_) {
      if (_trusted[implementation]) revert InvalidRequest();
    } else if (!_trusted[implementation]) revert InvalidRequest();
    bytes32 operation = keccak256(abi.encode(this.trust.selector, implementation, trusted_));
    if (_canExecute(delay, oType, operation)) {
      if (trusted_) _trusted[implementation] = trusted_;
      else delete _trusted[implementation];
      emit Trusted(implementation, trusted_);
    }
  }

  /**
   * @notice Returns the manager version required by a trusted implementation
   * @param implementation The address of the implementation
   * @return True if a trusted implementation
   */
  function trusted(address implementation) external view override returns (bool) {
    return _trusted[implementation];
  }
}
