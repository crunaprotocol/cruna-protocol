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
   */
  enum Level {
    NONE,
    LOW,
    MEDIUM,
    HIGH
  }

  /**
   * @dev Protectors, beneficiaries and recipients are actors
   */
  struct Actor {
    address actor;
    Status status;
    Level level;
  }
}
