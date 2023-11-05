// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {IActor} from "./IActor.sol";

// erc165 interfaceId 0x8dca4bea
interface IProtected {
  /**
   * @dev Emitted when a protector is set for an tokensOwner
   */
  event ProtectorUpdated(address indexed tokensOwner, address indexed protector, bool status);

  /**
   * @dev Emitted when the level of an allowed recipient is updated
   */
  event SafeRecipientUpdated(address indexed owner, address indexed recipient, IActor.Level level);

  /**
   * @dev Emitted when a beneficiary is updated
   */
  event BeneficiaryUpdated(address indexed owner, address indexed beneficiary, IActor.Status status);

  error NotTheTokenOwner();
  error NotApprovable();
  error NotApprovableForAll();
  error NotTheContractDeployer();
  error TokenDoesNotExist();
  error SenderDoesNotOwnAnyToken();
  error ProtectorNotFound();
  error TokenAlreadyBeingTransferred();
  error AssociatedToAnotherOwner();
  error ProtectorAlreadySet();
  error ProtectorAlreadySetByYou();
  error NotAProtector();
  error NotOwnByRelatedOwner();
  error NotPermittedWhenProtectorsAreActive();
  error TokenIdTooBig();
  error PendingProtectorNotFound();
  error ResignationAlreadySubmitted();
  error UnsetNotStarted();
  error NotTheProtector();
  error NotATokensOwner();
  error ResignationNotSubmitted();
  error InvalidDuration();
  error NoActiveProtectors();
  error ProtectorsAlreadyLocked();
  error ProtectorsUnlockAlreadyStarted();
  error ProtectorsUnlockNotStarted();
  error ProtectorsNotLocked();
  error TimestampInvalidOrExpired();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();
  error OperatorAlreadyActive();
  error OperatorNotActive();
  error NotTheVaultManager();
  error QuorumCannotBeZero();
  error QuorumCannotBeGreaterThanBeneficiaries();
  error BeneficiaryNotConfigured();
  error NotExpiredYet();
  error BeneficiaryAlreadyRequested();
  error InconsistentRecipient();
  error NotABeneficiary();
  error RequestAlreadyApproved();
  error NotTheRecipient();
  error Unauthorized();
  error NotTransferable();
  error NotTheManager();
  error InvalidManager();
  error InvalidSignatureValidator();

  /**
   * @dev Transfers a token to a recipient usign a valid signed transferRequest
   * @notice The function MUST be executed by the owner
   * @param tokenId The token id
   * @param to The address of the recipient
   * @param timestamp The timestamp of the transfer request
   * @param signature The signature of the transfer request, signed by an active protector
   */
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external;

  function managedTransfer(uint256 tokenId, address to) external;
}
