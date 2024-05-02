// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

/**
 * @title ITimeControlledGovernance.sol
 * @notice An optimized time controlled proposers/executors contract
 */
interface ITimeControlledGovernance {
  enum OperationType {
    Proposal,
    Cancellation,
    Execution
  }

  enum Role {
    Proposer,
    Executor,
    // only for cancellations and to check if the sender has already a role
    Any
  }

  struct Authorized {
    address addr;
    // it can be only a proposer or an executor
    Role role;
  }

  // more specific events should be emitted by the contract extending this one

  event OperationProposed(bytes32 operation, address proposer, uint256 delay);
  event OperationExecuted(bytes32 operation, address executor);

  // when cancelling, the executor can also be the proposer
  event OperationCancelled(bytes32 operation, address executor);

  event AdminRenounced();

  /**
   * @notice Error returned when the delay is invalid
   */
  error InvalidDelay();
  error InvalidRequest();
  error TooEarlyToExecute();
  error AlreadyProposed();
  error InvalidRole();
  error Forbidden();
  error RoleNeeded();
  error ProposalNotFound();

  function renounceAdmin() external;

  function setMinDelay(uint256 delay, OperationType oType, uint256 minDelay) external;

  function setAuthorized(uint256 delay, OperationType oType, address toBeAuthorized, Role role, bool active) external;

  function getMinDelay() external view returns (uint256);

  function getAdmin() external view returns (address);

  function getAuthorized() external view returns (Authorized[] memory);

  function getOperation(bytes32 operation) external view returns (uint256);

  function isAuthorized(address sender, Role role_) external view returns (bool);

  function countAuthorized() external view returns (uint256, uint256);
}
