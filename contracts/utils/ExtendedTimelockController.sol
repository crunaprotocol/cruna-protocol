// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

contract ExtendedTimelockController is TimelockController {
  error MustCallThroughTimeController();

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
  ) TimelockController(minDelay, proposers, executors, admin) {}

  /**
   * @dev Adds a new proposer.
   * Can only be called through the TimelockController.
   */
  function addProposer(address proposer) external onlyThroughTimeController {
    _grantRole(PROPOSER_ROLE, proposer);
  }

  /**
   * @dev Removes a proposer.
   * Can only be called through the TimelockController.
   */
  function removeProposer(address proposer) external onlyThroughTimeController {
    _revokeRole(PROPOSER_ROLE, proposer);
  }

  /**
   * @dev Adds a new executor.
   * Can only be called through the TimelockController.
   */
  function addExecutor(address executor) external onlyThroughTimeController {
    _grantRole(EXECUTOR_ROLE, executor);
  }

  /**
   * @dev Removes an executor.
   * Can only be called through the TimelockController.
   */
  function removeExecutor(address executor) external onlyThroughTimeController {
    _revokeRole(EXECUTOR_ROLE, executor);
  }
}
