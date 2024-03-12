// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "hardhat/console.sol";

/**
  @title ISignatureValidator
  @author Francesco Sullo <francesco@sullo.co>
  @dev Validates signatures
*/
interface ISignatureValidator {
  /**
    @dev Emitted when a signature is pre-approved.
    @param hash The hash of the signature.
    @param signer The signer of the signature.
  */
  event PreApproved(bytes32 hash, address indexed signer);

  /// @dev Error returned when a timestamp is invalid or expired.
  error TimestampInvalidOrExpired();

  /// @dev Error returned when a called in unauthorized.
  error NotAuthorized();

  /// @dev Error returned when trying to call a protected operation without a valid signature
  error NotPermittedWhenProtectorsAreActive();

  /// @dev Error returned when the signature is not valid.
  error WrongDataOrNotSignedByProtector();

  /// @dev Error returned when the signature is already used.
  error SignatureAlreadyUsed();

  /**
    @dev Returns the address who approved a pre-approved operation.
    @param hash The hash of the operation.
  */
  function preApprovals(bytes32 hash) external view returns (address);

  /**
    @dev Returns the hash of a signature.
    @param signature The signature.
  */
  function hashSignature(bytes calldata signature) external pure returns (bytes32);

  /**
    @dev Returns if a signature has been used.
    @param hash The hash of the signature.
  */
  function isSignatureUsed(bytes32 hash) external view returns (bool);

  /**
    @dev This function validates a signature trying to be as flexible as possible.
      As long as called inside the same contract, the cost adding some more parameters is negligible.
      Instead, calling it from other contracts can be expensive.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
     It can be address(0) if the parameter is not needed.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature.
    @return The signer of the signature and the hash of the signature.
  */
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

  /**
    @dev Pre-approve a signature.
    @param selector The selector of the function being called.
    @param owner The owner of the token.
    @param actor The actor being authorized.
     It can be address(0) if the parameter is not needed.
    @param tokenAddress The address of the token.
    @param tokenId The id of the token.
    @param extra The extra
    @param extra2 The extra2
    @param extra3 The extra3
    @param timeValidation A combination of timestamp and validity of the signature.
  */
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
