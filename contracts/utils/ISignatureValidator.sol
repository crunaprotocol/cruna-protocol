// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

interface ISignatureValidator {
  event PreApproved(bytes32 hash, address indexed signer);

  error TimestampInvalidOrExpired();
  error NotAuthorized();
  error NotPermittedWhenProtectorsAreActive();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();

  function preApprovals(bytes32 hash) external view returns (address);

  function hashSignature(bytes calldata signature) external pure returns (bytes32);

  function isSignatureUsed(bytes32 hash) external view returns (bool);

  // @dev This function validates a signature trying to be as flexible as possible.
  //   As long as called inside the same contract, the cost adding some more parameters is negligible. Instead, calling it from other contracts can be expensive.
  // @param selector The selector of the function being called.
  // @param owner The owner of the token.
  // @param actor The actor being authorized.
  //   It can be address(0) if the parameter is not needed.
  // @param tokenAddress The address of the token.
  // @param tokenId The id of the token.
  // @param extra The extra
  // @param extra2 The extra2
  // @param extra3 The extra3
  // @param timeValidation A combination of timestamp and validity of the signature.
  //   To be readable, the value is calculated as
  //     timestamp * _TIMESTAMP_MULTIPLIER + validity
  // @param Returns the signer of the signature.
  function recoverSigner(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation,
    bytes calldata signature
  ) external view returns (address, bytes32);

  function preApprove(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation
  ) external;
}
