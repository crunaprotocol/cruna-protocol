// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

// import {console} from "hardhat/console.sol";

// @dev This contract manages actors
interface IActor {
  error ZeroAddress();
  error ActorAlreadyAdded();
  error TooManyActors();

  function getActors(bytes4 role) external view returns (address[] memory);

  function actorIndex(address actor_, bytes4 role) external view returns (uint256);

  function actorCount(bytes4 role) external view returns (uint256);
}
