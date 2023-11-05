// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

interface IActor {
  error NoZeroAddress();
  error InvalidRole();
  error ActorNotFound(bytes32);
  error ActorAlreadyAdded();
  error TooManyActors();

  enum Status {
    UNSET,
    PENDING,
    ACTIVE,
    RESIGNED
  }

  /**
    * @dev Recipients can have different levels of protection
       a recipient level LOW or MEDIUM can move assets inside the vault skipping the protector
       a recipient level HIGH can receive the CrunaFlexiVault.sol skipping the protector
    */
  enum Level {
    NONE,
    LOW,
    MEDIUM,
    HIGH
  }

  /**
    * @dev Protectors, beneficiaries and recipients are actors
    * @notice Actor.sol are set for the tokensOwner, not for the specific token,
       to reduce gas consumption.
    */
  struct Actor {
    address actor;
    Status status;
    Level level;
  }
}
