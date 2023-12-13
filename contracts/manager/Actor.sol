// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

//import {console} from "hardhat/console.sol";

// @dev This contract manages actors
contract Actor {
  error ZeroAddress();
  error ActorNotFound(bytes32);
  error ActorAlreadyAdded();
  error TooManyActors();

  uint256 public constant MAX_ACTORS = 16;

  mapping(bytes32 => address[]) private _actors;

  function getActors(bytes32 role) public view returns (address[] memory) {
    return _actors[role];
  }

  function actorIndex(address actor_, bytes32 role) public view returns (uint256) {
    address[] storage actors = _actors[role];
    // This may go out of gas if there are too many actors
    for (uint256 i = 0; i < actors.length; i++) {
      if (actors[i] == actor_) {
        return i;
      }
    }
    return MAX_ACTORS;
  }

  function actorCount(bytes32 role) public view returns (uint256) {
    return _actors[role].length;
  }

  function _isActiveActor(address actor_, bytes32 role) internal view returns (bool) {
    uint256 i = actorIndex(actor_, role);
    return i < MAX_ACTORS;
  }

  function _removeActor(address actor_, bytes32 role) internal {
    uint256 i = actorIndex(actor_, role);
    _removeActorByIndex(i, role);
  }

  function _removeActorByIndex(uint256 i, bytes32 role) internal {
    address[] storage actors = _actors[role];
    if (i < actors.length - 1) {
      actors[i] = actors[actors.length - 1];
    }
    actors.pop();
  }

  function _addActor(address actor_, bytes32 role_) internal {
    if (actor_ == address(0)) revert ZeroAddress();
    // We allow to add up to 16 actors per role per owner to avoid the risk of going out of gas
    // looping the array. Most likely, the user will set between 1 and 7 actors per role, so,
    // it should be fine
    if (_actors[role_].length == MAX_ACTORS - 1) revert TooManyActors();
    if (_isActiveActor(actor_, role_)) revert ActorAlreadyAdded();
    _actors[role_].push(actor_);
  }

  function _deleteActors(bytes32 role) internal {
    delete _actors[role];
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
