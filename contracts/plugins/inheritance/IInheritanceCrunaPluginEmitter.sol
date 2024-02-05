// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

interface IInheritanceCrunaPluginEmitter {
  // @dev Emitted when a sentinel is updated
  event SentinelUpdated(uint256 indexed tokenId_, address indexed owner, address indexed sentinel, bool status);

  event InheritanceConfigured(
    uint256 indexed tokenId_,
    address indexed owner,
    uint256 quorum,
    uint256 proofOfLifeDurationInDays,
    uint256 gracePeriod,
    address beneficiary
  );

  event ProofOfLife(uint256 indexed tokenId_, address indexed owner);

  event TransferRequested(uint256 indexed tokenId_, address indexed sentinel, address indexed beneficiary);

  event TransferRequestApproved(uint256 indexed tokenId_, address indexed sentinel);

  // a generic, inefficient event that can be used if an upgraded implementation requires more events
  event FutureEvent(
    uint256 indexed tokenId_,
    string indexed eventName,
    address indexed actor,
    bool status,
    uint256 extraUint256,
    bytes32 extraBytes32
  );

  function emitSentinelUpdatedEvent(uint256 tokenId_, address owner, address sentinel, bool status) external;

  function emitInheritanceConfiguredEvent(
    uint256 tokenId_,
    address owner,
    uint256 quorum,
    uint256 proofOfLifeDurationInDays,
    uint256 gracePeriod,
    address beneficiary
  ) external;

  function emitProofOfLifeEvent(uint256 tokenId_, address owner) external;

  function emitTransferRequestedEvent(uint256 tokenId_, address sentinel, address beneficiary) external;

  function emitTransferRequestApprovedEvent(uint256 tokenId_, address sentinel) external;

  function emitFutureEvent(
    uint256 tokenId_,
    string memory eventName,
    address actor,
    bool status,
    uint256 extraUint256,
    bytes32 extraBytes32
  ) external;
}
