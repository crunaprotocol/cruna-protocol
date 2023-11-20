// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>
import {IActor} from "./IActor.sol";

//import {console} from "hardhat/console.sol";

contract Actor is IActor {
  error ZeroAddress();
  error ActorNotFound(bytes32);
  error ActorAlreadyAdded();
  error TooManyActors();

  mapping(bytes32 => Actor[]) private _actors;
  Actor private _emptyActor = Actor(address(0), Status.UNSET, Level.NONE);

  function _getActors(bytes32 role) internal view returns (Actor[] memory) {
    return _actors[role];
  }

  function _getActor(address actor_, bytes32 role) internal view returns (uint256, Actor storage) {
    Actor[] storage actors = _actors[role];
    // This may go out of gas if there are too many actors
    for (uint256 i = 0; i < actors.length; i++) {
      if (actors[i].actor == actor_) {
        return (i, actors[i]);
      }
    }
    // Caller must check _emptyActor.status
    // If not, must call _findActor, which reverts if actor not found
    return (0, _emptyActor);
  }

  // similar to getActor, but reverts if actor not found
  function _findActor(address actor_, bytes32 role) internal view returns (uint256, Actor storage) {
    (uint256 i, Actor storage actor) = _getActor(actor_, role);
    if (actor.status == Status.UNSET) {
      revert ActorNotFound(role);
    }
    return (i, actor);
  }

  function _actorStatus(address actor_, bytes32 role) internal view returns (Status) {
    (, Actor storage actor) = _getActor(actor_, role);
    return actor.status;
  }

  function _actorLength(bytes32 role) internal view returns (uint256) {
    return _actors[role].length;
  }

  function _actorLevel(address actor_, bytes32 role) internal view returns (Level) {
    (, Actor storage actor) = _findActor(actor_, role);
    return actor.level;
  }

  function _isActiveActor(address actor_, bytes32 role) internal view returns (bool) {
    Status status = _actorStatus(actor_, role);
    return status > Status.PENDING;
  }

  function _listActiveActors(bytes32 role) internal view returns (address[] memory) {
    uint256 count = role == _role("PROTECTOR") ? _countActiveActorsByRole(role) : _actorLength(role);
    address[] memory actors = new address[](count);
    uint256 j = 0;
    for (uint256 i = 0; i < _actors[role].length; i++) {
      if (_actors[role][i].status > Status.PENDING) {
        actors[j] = _actors[role][i].actor;
        j++;
      }
    }
    return actors;
  }

  function _countActiveActorsByRole(bytes32 role) internal view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < _actors[role].length; i++) {
      if (_actors[role][i].status > Status.PENDING) {
        count++;
      }
    }
    return count;
  }

  function _updateStatus(uint256 i, bytes32 role, Status status_) internal {
    _actors[role][i].status = status_;
  }

  function _updateLevel(uint256 i, bytes32 role, Level level_) internal {
    _actors[role][i].level = level_;
  }

  function _removeActor(address actor_, bytes32 role) internal {
    (uint256 i, ) = _findActor(actor_, role);
    _removeActorByIndex(i, role);
  }

  function _removeActorByIndex(uint256 i, bytes32 role) internal {
    Actor[] storage actors = _actors[role];
    if (i < actors.length - 1) {
      actors[i] = actors[actors.length - 1];
    }
    actors.pop();
  }

  function _addActor(address actor_, bytes32 role, Status status_, Level level) internal {
    if (actor_ == address(0)) revert ZeroAddress();
    // We allow to add up to 16 actors per role per owner to avoid the risk of going out of gas
    // looping the array. Most likely, the user will set between 1 and 7 actors per role, so,
    // it should be fine
    if (_actors[role].length > 16) revert TooManyActors();
    Status status = _actorStatus(actor_, role);
    if (status != Status.UNSET) revert ActorAlreadyAdded();
    _actors[role].push(Actor(actor_, status_, level));
  }

  function _role(string memory role_) internal pure returns (bytes32) {
    return keccak256(bytes(role_));
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}
