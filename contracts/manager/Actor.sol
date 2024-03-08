// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// import {console} from "hardhat/console.sol";
import {IActor} from "./IActor.sol";

// @dev This contract manages actors
contract Actor is IActor {
  uint256 public constant MAX_ACTORS = 16;

  mapping(bytes4 => address[]) internal _actors;

  function getActors(bytes4 role) public view virtual override returns (address[] memory) {
    return _actors[role];
  }

  function actorIndex(address actor_, bytes4 role) public view virtual override returns (uint256) {
    address[] storage actors = _actors[role];
    // This may go out of gas if there are too many actors
    uint256 len = actors.length;
    for (uint256 i; i < len; i++) {
      if (actors[i] == actor_) {
        return i;
      }
    }
    return MAX_ACTORS;
  }

  function actorCount(bytes4 role) public view virtual override returns (uint256) {
    return _actors[role].length;
  }

  function _isActiveActor(address actor_, bytes4 role) internal view virtual returns (bool) {
    uint256 i = actorIndex(actor_, role);
    return i < MAX_ACTORS;
  }

  function _removeActor(address actor_, bytes4 role) internal virtual {
    uint256 i = actorIndex(actor_, role);
    _removeActorByIndex(i, role);
  }

  function _removeActorByIndex(uint256 i, bytes4 role) internal virtual {
    address[] storage actors = _actors[role];
    if (i < actors.length - 1) {
      actors[i] = actors[actors.length - 1];
    }
    actors.pop();
  }

  function _addActor(address actor_, bytes4 role_) internal virtual {
    if (actor_ == address(0)) revert ZeroAddress();
    // We allow to add up to 16 actors per role per owner to avoid the risk of going out of gas
    // looping the array. Most likely, the user will set between 1 and 7 actors per role, so,
    // it should be fine
    if (_actors[role_].length == MAX_ACTORS - 1) revert TooManyActors();
    if (_isActiveActor(actor_, role_)) revert ActorAlreadyAdded();
    _actors[role_].push(actor_);
  }

  function _deleteActors(bytes4 role) internal virtual {
    delete _actors[role];
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
