// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title FlexiTimelockController
 * @author Francesco Sullo <francesco@sullo.co>
 * @dev Extension of the TimelockController that allows for upgrade proposers and executors if needed.
 */
contract FlexiTimelockController is TimelockController {
  /// @dev Error returned when the function is not called through the TimelockController
  error MustCallThroughTimeController();

  /// @dev Error returned when trying to add an already existing proposer
  error ProposerAlreadyExists();

  /// @dev Error returned when trying to remove a non-existing proposer
  error ProposerDoesNotExist();

  /// @dev Error returned when trying to add an already existing executor
  error ExecutorAlreadyExists();

  /// @dev Error returned when trying to remove a non-existing executor
  error ExecutorDoesNotExist();

  /// @dev Modifier to allow only the TimelockController to call a function.
  modifier onlyThroughTimeController() {
    if (msg.sender != address(this)) revert MustCallThroughTimeController();
    _;
  }

  /**
   * @dev Initializes the contract with a given minDelay and initial proposers and executors.
   * @param minDelay The minimum delay for the time lock.
   * @param proposers The initial proposers.
   * @param executors The initial executors.
   * @param admin The admin of the contract (they should later renounce to the role).
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
    if (hasRole(PROPOSER_ROLE, proposer)) revert ProposerAlreadyExists();
    _grantRole(PROPOSER_ROLE, proposer);
  }

  /**
   * @dev Removes a proposer.
   * Can only be called through the TimelockController.
   */
  function removeProposer(address proposer) external onlyThroughTimeController {
    if (!hasRole(PROPOSER_ROLE, proposer)) revert ProposerDoesNotExist();
    _revokeRole(PROPOSER_ROLE, proposer);
  }

  /**
   * @dev Adds a new executor.
   * Can only be called through the TimelockController.
   */
  function addExecutor(address executor) external onlyThroughTimeController {
    if (hasRole(EXECUTOR_ROLE, executor)) revert ExecutorAlreadyExists();
    _grantRole(EXECUTOR_ROLE, executor);
  }

  /**
   * @dev Removes an executor.
   * Can only be called through the TimelockController.
   */
  function removeExecutor(address executor) external onlyThroughTimeController {
    if (!hasRole(EXECUTOR_ROLE, executor)) revert ExecutorDoesNotExist();
    _revokeRole(EXECUTOR_ROLE, executor);
  }
}
