// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

import {ITimeControlledGovernance} from "./ITimeControlledGovernance.sol";

/**
 * @title TimeControlledGovernance.sol
 * @notice An optimized time controlled proposers/executors contract
 */
contract TimeControlledGovernance is ITimeControlledGovernance {
  /**
   * @notice The minimum delay for time lock operations
   */
  uint256 private _minDelay;
  /**
   * @notice The address that can admin the contract.
   * It should renounce to the role, as soon as possible.
   */
  address private _admin;

  /**
   * @notice The authorized addresses
   * the array should not contain too many elements to avoid
   * out-of-gas issues when looping over it
   */
  Authorized[] private _authorized;

  /**
   * @notice The operations by encoded parameters of the operation
   */
  mapping(bytes32 => uint256) private _operations;

  /**
   * @param minDelay The minimum delay for time lock operations
   * @param firstProposer The address that can propose time lock operations
   * @param firstExecutor The address that can execute time lock operations
   * @param admin The address that can admin the contract.
   * It should renounce to the role, as soon as possible.
   */
  constructor(uint256 minDelay, address firstProposer, address firstExecutor, address admin) {
    _minDelay = minDelay;
    if (firstProposer == firstExecutor) revert InvalidRequest();
    _authorized.push(Authorized(firstProposer, Role.Proposer));
    _authorized.push(Authorized(firstExecutor, Role.Executor));
    _admin = admin;
  }

  /**
   * @notice Get the list of all authorized addresses
   */
  function getAuthorized() public view override returns (Authorized[] memory) {
    return _authorized;
  }

  /**
   * @notice Get the min delay
   */
  function getMinDelay() public view override returns (uint256) {
    return _minDelay;
  }

  /**
   * @notice Get the admin
   */
  function getAdmin() public view override returns (address) {
    return _admin;
  }

  /**
   * @notice Check if an address is authorized
   * @param sender The address to check
   * @param role_ The role to check
   */
  function isAuthorized(address sender, Role role_) public view returns (bool) {
    uint256 len = _authorized.length;
    for (uint256 i = 0; i < len; ) {
      if (_authorized[i].addr == sender)
        if (_authorized[i].role == role_ || role_ == Role.Any) return true;
      unchecked {
        ++i;
      }
    }
    return false;
  }

  /**
   * @notice Count the number of proposers and executors
   */
  function countAuthorized() public view returns (uint256, uint256) {
    uint256 proposers;
    uint256 executors;
    uint256 len = _authorized.length;
    for (uint256 i = 0; i < len; ) {
      if (_authorized[i].role == Role.Proposer) proposers++;
      else if (_authorized[i].role == Role.Executor) executors++;
      unchecked {
        ++i;
      }
    }
    return (proposers, executors);
  }

  /**
   * @notice Set the min delay
   * @param delay The delay before the operation can be executed
   * @param oType The type of operation
   * @param minDelay The new min delay
   */
  function setMinDelay(uint256 delay, OperationType oType, uint256 minDelay) external override {
    bytes32 operation = keccak256(abi.encode(this.setMinDelay.selector, minDelay));
    if (_canExecute(delay, oType, operation)) {
      _minDelay = minDelay;
    }
  }

  /**
   * @notice Renounce the admin role
   */
  function renounceAdmin() external override {
    if (msg.sender != _admin) revert Forbidden();
    _admin = address(0);
    emit AdminRenounced();
  }

  /**
   * @notice Authorize a new proposer/executor
   * @param delay The delay before the operation can be executed
   * @param oType The type of operation
   * @param toBeAuthorized The address to be authorized
   * @param role The role of the address
   * @param active If true, the address is active, otherwise if to be removed
   */
  function setAuthorized(uint256 delay, OperationType oType, address toBeAuthorized, Role role, bool active) external override {
    if (role == Role.Any) revert InvalidRole();
    if (active) {
      if (isAuthorized(toBeAuthorized, Role.Any)) revert InvalidRequest();
    } else {
      if (!isAuthorized(toBeAuthorized, role)) revert InvalidRequest();
      // at least one proposer and one executor must be active
      (uint256 proposers, uint256 executors) = countAuthorized();
      if (role == Role.Proposer) {
        if (proposers == 1) revert RoleNeeded();
      } else if (executors == 1) revert RoleNeeded();
    }
    bytes32 operation = keccak256(abi.encode(this.setAuthorized.selector, toBeAuthorized, role, active));
    if ((_admin != address(0) && msg.sender == _admin) || _canExecute(delay, oType, operation)) {
      if (active) {
        _authorized.push(Authorized(toBeAuthorized, role));
      } else {
        for (uint256 i = 0; i < _authorized.length; ) {
          if (_authorized[i].addr == toBeAuthorized) {
            _authorized[i] = _authorized[_authorized.length - 1];
            _authorized.pop();
            break;
          }
          unchecked {
            ++i;
          }
        }
      }
    }
  }

  /**
   * @notice Get info about an operation
   * @param operation The operation
   */
  function getOperation(bytes32 operation) public view override returns (uint256) {
    return _operations[operation];
  }

  function _canExecute(uint256 delay, OperationType oType, bytes32 operation) internal returns (bool) {
    uint256 executableAt = _operations[operation];
    if (oType == OperationType.Proposal) {
      if (executableAt > 0) revert AlreadyProposed();
    } else if (executableAt == 0) revert ProposalNotFound();
    //
    if (oType == OperationType.Proposal) {
      if (!isAuthorized(msg.sender, Role.Proposer)) revert Forbidden();
      if (delay < _minDelay) revert InvalidDelay();
      _operations[operation] = block.timestamp + delay;
      emit OperationProposed(operation, msg.sender, delay);
      return false;
    } else if (oType == OperationType.Cancellation) {
      // both proposers and executors can cancel a proposal
      if (!isAuthorized(msg.sender, Role.Any)) revert Forbidden();
      delete _operations[operation];
      emit OperationCancelled(operation, msg.sender);
      return false;
    } else if (oType == OperationType.Execution) {
      if (!isAuthorized(msg.sender, Role.Executor)) revert Forbidden();
      if (block.timestamp < executableAt) revert TooEarlyToExecute();
      delete _operations[operation];
      emit OperationExecuted(operation, msg.sender);
      return true;
    }
    revert InvalidRequest();
  }
}
