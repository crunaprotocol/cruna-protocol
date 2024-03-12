// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// import {console} from "hardhat/console.sol";

/**
  @title Actor
  @dev This contract manages actors (protectors, safe recipients, sentinels, etc.)
*/
contract Actor {
  /// @dev The maximum number of actors that can be set
  uint256 private constant _MAX_ACTORS = 16;

  /// @dev The actors for each role
  mapping(bytes4 role => address[] actors) internal _actors;

  /// @dev Error returned when trying to add a zero address
  error ZeroAddress();

  /// @dev Error returned when trying to add an actor already added
  error ActorAlreadyAdded();

  /// @dev Error returned when trying to add too many actors
  error TooManyActors();

  /// @dev Error returned when an actor is not found
  error ActorNotFound();

  /**
    @dev Returns the actors for a role
    @param role The role
    @return The actors
  */
  function _getActors(bytes4 role) internal view virtual returns (address[] memory) {
    return _actors[role];
  }

  /**
    @dev Returns the index of an actor for a role
    @param actor_ The actor
    @param role The role
    @return The index. If the index == _MAX_ACTORS, the actor is not found
  */
  function _actorIndex(address actor_, bytes4 role) internal view virtual returns (uint256) {
    address[] storage actors = _actors[role];
    // This may go out of gas if there are too many actors
    uint256 len = actors.length;
    for (uint256 i; i < len; ) {
      if (actors[i] == actor_) {
        return i;
      }
      unchecked {
        ++i;
      }
    }
    return _MAX_ACTORS;
  }

  /**
    @dev Returns the number of actors for a role
    @param role The role
    @return The number of actors
  */
  function _actorCount(bytes4 role) internal view virtual returns (uint256) {
    return _actors[role].length;
  }

  /**
    @dev Returns if an actor is active for a role
    @param actor_ The actor
    @param role The role
    @return If the actor is active
  */
  function _isActiveActor(address actor_, bytes4 role) internal view virtual returns (bool) {
    uint256 i = _actorIndex(actor_, role);
    return i < _MAX_ACTORS;
  }

  /**
    @dev Removes an actor for a role
    @param actor_ The actor
    @param role The role
  */
  function _removeActor(address actor_, bytes4 role) internal virtual {
    uint256 i = _actorIndex(actor_, role);
    _removeActorByIndex(i, role);
  }

  /**
    @dev Removes an actor for a role by index
    @param i The index
    @param role The role
  */
  function _removeActorByIndex(uint256 i, bytes4 role) internal virtual {
    address[] storage actors = _actors[role];
    unchecked {
      if (actors.length == 0 || i + 1 > actors.length) revert ActorNotFound();
      if (i != actors.length - 1) {
        actors[i] = actors[actors.length - 1];
      }
    }
    actors.pop();
  }

  /**
    @dev Adds an actor for a role
    @param actor_ The actor
    @param role_ The role
  */
  function _addActor(address actor_, bytes4 role_) internal virtual {
    if (actor_ == address(0)) revert ZeroAddress();
    // We allow to add up to 16 actors per role per owner to avoid the risk of going out of gas
    // looping the array. Most likely, the user will set between 1 and 7 actors per role, so,
    // it should be fine
    if (_actors[role_].length == _MAX_ACTORS - 1) revert TooManyActors();
    if (_isActiveActor(actor_, role_)) revert ActorAlreadyAdded();
    _actors[role_].push(actor_);
  }

  /**
    @dev Deletes all the actors for a role
    @param role The role
  */
  function _deleteActors(bytes4 role) internal virtual {
    delete _actors[role];
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
