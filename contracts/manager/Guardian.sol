// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Versioned} from "../utils/Versioned.sol";

//import "hardhat/console.sol";

/**
 * @dev Manages upgrade and cross-chain execution settings for accounts
 */
contract Guardian is Ownable2Step, Versioned {
  error ZeroAddress();
  error InvalidArguments();

  mapping(bytes4 => mapping(address => uint256)) private _isTrustedImplementation;

  event TrustedImplementationUpdated(bytes4 nameId, address implementation, bool trusted, uint256 requires);

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
  function setTrustedImplementation(bytes4 nameId, address implementation, bool trusted, uint256 requires) external onlyOwner {
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
