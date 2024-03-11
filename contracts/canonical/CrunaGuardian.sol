// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {FlexiTimelockController} from "../utils/FlexiTimelockController.sol";

// import "hardhat/console.sol";

/** @title CrunaGuardian
  @dev Manages a registry of trusted implementations and their required manager versions
  It is used by
  - manager and plugins to upgrade its own  implementation
  - manager to trust a new plugin implementation and allow managed transfers
 */
contract CrunaGuardian is ICrunaGuardian, IVersioned, FlexiTimelockController {
  error InvalidArguments();

  mapping(bytes32 nameIdAndImplementationAddress => uint256 requiredManagerVersion) private _trustedImplementations;

  // when deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) FlexiTimelockController(minDelay, proposers, executors, admin) {}

  function version() external pure virtual returns (uint256) {
    // v1.1.0
    return 1_001_000;
  }

  // @dev see {ICrunaGuardian.sol-setTrustedImplementation}
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
