// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICrunaGuardian} from "./ICrunaGuardian.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {FlexiTimelockController} from "../utils/FlexiTimelockController.sol";

// import "hardhat/console.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
contract CrunaGuardian is ICrunaGuardian, IVersioned, FlexiTimelockController {
  error InvalidArguments();

  mapping(bytes4 => mapping(address => uint256)) private _isTrustedImplementation;

  // when deployed to production, proposers and executors will be multi-sig wallets owned by the Cruna DAO
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) FlexiTimelockController(minDelay, proposers, executors, admin) {}

  function version() public pure virtual returns (uint256) {
    return 1_000_000;
  }

  // @dev see {ICrunaGuardian.sol-setTrustedImplementation}
  function setTrustedImplementation(
    bytes4 nameId,
    address implementation,
    bool trusted,
    uint256 requires
  ) external onlyThroughTimeController {
    if (requires == 0) {
      revert InvalidArguments();
    }
    if (trusted) {
      _isTrustedImplementation[nameId][implementation] = requires;
    } else {
      delete _isTrustedImplementation[nameId][implementation];
    }
    emit TrustedImplementationUpdated(nameId, implementation, trusted, requires);
  }

  function trustedImplementation(bytes4 nameId, address implementation) external view returns (uint256) {
    return _isTrustedImplementation[nameId][implementation];
  }
}
