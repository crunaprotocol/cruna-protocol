// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract FlexiTimelockController is TimelockController {
  uint256 public totalProposers;
  uint256 public totalExecutors;

  error MustCallThroughTimeController();
  error ProposerAlreadyExists();
  error ProposerDoesNotExist();
  error ExecutorAlreadyExists();
  error ExecutorDoesNotExist();

  modifier onlyThroughTimeController() {
    if (msg.sender != address(this)) revert MustCallThroughTimeController();
    _;
  }

  /**
   * @dev Initializes the contract with a given minDelay and initial proposers and executors.
   * Proposers and executors can be changed later respecting the time lock rules.
   */
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address admin
  ) TimelockController(minDelay, proposers, executors, admin) {
    totalProposers = proposers.length;
    totalExecutors = executors.length;
  }

  /**
   * @dev Adds a new proposer.
   * Can only be called through the TimelockController.
   */
  function addProposer(address proposer) external onlyThroughTimeController {
    if (hasRole(PROPOSER_ROLE, proposer)) revert ProposerAlreadyExists();
    _grantRole(PROPOSER_ROLE, proposer);
    totalProposers++;
  }

  /**
   * @dev Removes a proposer.
   * Can only be called through the TimelockController.
   */
  function removeProposer(address proposer) external onlyThroughTimeController {
    if (!hasRole(PROPOSER_ROLE, proposer)) revert ProposerDoesNotExist();
    _revokeRole(PROPOSER_ROLE, proposer);
    totalProposers--;
  }

  /**
   * @dev Adds a new executor.
   * Can only be called through the TimelockController.
   */
  function addExecutor(address executor) external onlyThroughTimeController {
    if (hasRole(EXECUTOR_ROLE, executor)) revert ExecutorAlreadyExists();
    _grantRole(EXECUTOR_ROLE, executor);
    totalExecutors++;
  }

  /**
   * @dev Removes an executor.
   * Can only be called through the TimelockController.
   */
  function removeExecutor(address executor) external onlyThroughTimeController {
    if (!hasRole(EXECUTOR_ROLE, executor)) revert ExecutorDoesNotExist();
    _revokeRole(EXECUTOR_ROLE, executor);
    totalExecutors--;
  }
}
