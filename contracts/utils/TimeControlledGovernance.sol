// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

import {ITimeControlledGovernance} from "./ITimeControlledGovernance.sol";

/**
 * @title TimeControlledGovernance.sol
 * @notice An optimized time controlled proposers/executors contract
 */
contract TimeControlledGovernance is ITimeControlledGovernance {
  uint256 private _minDelay;
  address private _admin;

  // the array should not contain too many elements to avoid
  // out-of-gas issues when looping over it
  Authorized[] private _authorized;

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

  function getAuthorized() public view override returns (Authorized[] memory) {
    return _authorized;
  }

  function getMinDelay() public view override returns (uint256) {
    return _minDelay;
  }

  function getAdmin() public view override returns (address) {
    return _admin;
  }

  function isAuthorized(address sender, Role role_) public view returns (bool) {
    for (uint256 i = 0; i < _authorized.length; ) {
      if (_authorized[i].addr == sender)
        if (_authorized[i].role == role_ || role_ == Role.Any) return true;
      unchecked {
        ++i;
      }
    }
    return false;
  }

  function countAuthorized() public view returns (uint256, uint256) {
    uint256 proposers;
    uint256 executors;
    for (uint256 i = 0; i < _authorized.length; ) {
      if (_authorized[i].role == Role.Proposer) proposers++;
      else if (_authorized[i].role == Role.Executor) executors++;
      unchecked {
        ++i;
      }
    }
    return (proposers, executors);
  }

  function setMinDelay(uint256 delay, OperationType oType, uint256 minDelay) external override {
    bytes32 operation = keccak256(abi.encode(this.setMinDelay.selector, minDelay));
    if (_canExecute(delay, oType, operation)) {
      _minDelay = minDelay;
    }
  }

  function renounceAdmin() external override {
    if (msg.sender != _admin) revert Forbidden();
    _admin = address(0);
    emit AdminRenounced();
  }

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
      // anyone can cancel a proposal
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
