// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Versioned} from "../utils/Versioned.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
contract FlexiGuardian is Ownable2Step, Versioned {
  error ZeroAddress();

  mapping(bytes32 => mapping(address => bool)) private _isTrustedImplementation;

  event TrustedImplementationUpdated(bytes32 scope, address implementation, bool trusted);

  constructor(address owner) {
    if (owner == address(0)) {
      revert ZeroAddress();
    }
    _transferOwnership(owner);
  }

  /**
   * @dev Sets a given implementation address as trusted, allowing accounts to upgrade to this
   * implementation
   */
  function setTrustedImplementation(bytes32 scope, address implementation, bool trusted) external onlyOwner {
    _isTrustedImplementation[scope][implementation] = trusted;
    emit TrustedImplementationUpdated(scope, implementation, trusted);
  }

  function isTrustedImplementation(bytes32 scope, address implementation) external view returns (bool) {
    return _isTrustedImplementation[scope][implementation];
  }
}
