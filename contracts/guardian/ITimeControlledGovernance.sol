// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

/**
 * @title ITimeControlledGovernance.sol
 * @notice An optimized time controlled proposers/executors contract
 */
interface ITimeControlledGovernance {
  /**
   * @notice The type of operation
   * - Proposal: a new operation is proposed
   * - Cancellation: an operation is cancelled
   * - Execution: an operation is executed
   */
  enum OperationType {
    Proposal,
    Cancellation,
    Execution
  }

  /**
   * @notice The role of the sender
   * - Proposer: the sender can propose operations
   * - Executor: the sender can execute operations
   * - Any: the sender can cancel operations and check if it has a role
   */
  enum Role {
    Proposer,
    Executor,
    // only for cancellations and to check if the sender has already a role
    Any
  }

  /**
   * @notice The structure of an authorized address
   * - addr: the address
   * - role: the role of the address
   */
  struct Authorized {
    address addr;
    // it can be only a proposer or an executor
    Role role;
  }

  /**
   * @notice Emitted when an operation is proposed
   * @param operation The hash of the operation
   * @param proposer The proposer
   * @param delay The delay before the operation can be executed
   */
  event OperationProposed(bytes32 operation, address proposer, uint256 delay);

  /**
   * @notice Emitted when an operation is executed
   * @param operation The hash of the operation
   * @param executor The executor
   */
  event OperationExecuted(bytes32 operation, address executor);

  /**
   * @notice Emitted when an operation is cancelled
   * Both proposer and executor can cancel an operation
   * @param operation The hash of the operation
   * @param executor The executor (it can be a proposer as well)
   */
  event OperationCancelled(bytes32 operation, address executor);

  /**
   * @notice Emitted when the admin is renounced
   */
  event AdminRenounced();

  /**
   * @notice Error returned when the delay is invalid
   */
  error InvalidDelay();
  /**
   * @notice Error returned when the request is invalid
   */
  error InvalidRequest();
  /**
   * @notice Error returned when it is too early to execute an operation
   */
  error TooEarlyToExecute();
  /**
   * @notice Error returned when the operation is already proposed
   */
  error AlreadyProposed();
  /**
   * @notice Error returned when the role is invalid
   */
  error InvalidRole();
  /**
   * @notice Error returned when the request is forbidden
   */
  error Forbidden();
  /**
   * @notice Error returned when trying to remove last proposer/executor
   */
  error RoleNeeded();
  /**
   * @notice Error returned when the operation is not found
   */
  error ProposalNotFound();

  /**
   * @notice Renounce the admin role
   */
  function renounceAdmin() external;

  /**
   * @notice Set the min delay
   * @param delay The delay before the operation can be executed
   * @param oType The type of operation
   * @param minDelay The new min delay
   */
  function setMinDelay(uint256 delay, OperationType oType, uint256 minDelay) external;

  /**
   * @notice Authorize a new proposer/executor
   * @param delay The delay before the operation can be executed
   * @param oType The type of operation
   * @param toBeAuthorized The address to be authorized
   * @param role The role of the address
   * @param active If true, the address is active, otherwise if to be removed
   */
  function setAuthorized(uint256 delay, OperationType oType, address toBeAuthorized, Role role, bool active) external;

  /**
   * @notice Get the min delay
   */
  function getMinDelay() external view returns (uint256);

  /**
   * @notice Get the admin
   */
  function getAdmin() external view returns (address);

  /**
   * @notice Get the list of all authorized addresses
   */
  function getAuthorized() external view returns (Authorized[] memory);

  /**
   * @notice Get info about an operation
   * @param operation The operation
   */
  function getOperation(bytes32 operation) external view returns (uint256);

  /**
   * @notice Check if an address is authorized
   * @param sender The address to check
   * @param role_ The role to check
   */
  function isAuthorized(address sender, Role role_) external view returns (bool);

  /**
   * @notice Count the number of proposers and executors
   */
  function countAuthorized() external view returns (uint256, uint256);
}
