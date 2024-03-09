// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {ISignatureValidator} from "./ISignatureValidator.sol";

// import "hardhat/console.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
abstract contract SignatureValidator is ISignatureValidator, EIP712, Context {
  using ECDSA for bytes32;

  uint256 internal constant _MAX_VALID_FOR = 9_999_999;
  uint256 internal constant _TIMESTAMP_MULTIPLIER = 1e7;
  uint256 internal constant _TIME_VALIDATION_MULTIPLIER = 1e17;

  mapping(bytes32 => address) private _preApprovals;
  mapping(bytes32 => bool) private _usedSignatures;

  constructor() EIP712("Cruna", "1") {}

  function preApprovals(bytes32 hash) external view override returns (address) {
    return _preApprovals[hash];
  }

  function usedSignatures(bytes32 hash) external view override returns (bool) {
    return _usedSignatures[hash];
  }

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
  ) public view override returns (address, bytes32) {
    _validate(timeValidation);
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    if (65 == signature.length) {
      return (_hashTypedDataV4(hash).recover(signature), hash);
    }
    return (_preApprovals[hash], hash);
  }

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
  ) external override {
    if (!_canPreApprove(selector, actor, _msgSender())) revert NotAuthorized();
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    _preApprovals[hash] = _msgSender();
    emit PreApproved(hash, _msgSender());
  }

  // @dev Must be implemented by the contract using this base contract
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool);

  function _validate(uint256 timeValidation) internal view {
    uint256 timestamp = timeValidation / _TIMESTAMP_MULTIPLIER;
    if (timestamp > block.timestamp || timestamp < block.timestamp - (timeValidation % _TIMESTAMP_MULTIPLIER))
      revert TimestampInvalidOrExpired();
  }

  // @dev Must be implemented by the contract using this base contract
  function _isProtected() internal view virtual returns (bool);

  // @dev Must be implemented by the contract using this base contract
  function _isProtector(address protector) internal view virtual returns (bool);

  function _validateAndCheckSignature(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    // we encode here the isProtector to avoid too many variables, when setting the first protector
    uint256 timeValidationAndSetProtector,
    bytes calldata signature
  ) internal virtual {
    if (
      timeValidationAndSetProtector < _TIME_VALIDATION_MULTIPLIER &&
      timeValidationAndSetProtector % _TIME_VALIDATION_MULTIPLIER < _TIMESTAMP_MULTIPLIER
    ) {
      if (_isProtected()) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (_usedSignatures[_hashBytes(signature)]) revert SignatureAlreadyUsed();
      _usedSignatures[_hashBytes(signature)] = true;
      (address signer, bytes32 hash) = recoverSigner(
        selector,
        owner,
        actor,
        tokenAddress,
        tokenId,
        extra,
        extra2,
        extra3,
        timeValidationAndSetProtector % _TIME_VALIDATION_MULTIPLIER,
        signature
      );
      if (timeValidationAndSetProtector > _TIME_VALIDATION_MULTIPLIER && !_isProtected()) {
        if (signer != actor) revert WrongDataOrNotSignedByProtector();
      } else if (!_isProtector(signer)) revert WrongDataOrNotSignedByProtector();
      delete _preApprovals[hash];
    }
  }

  function _hashData(
    bytes4 selector,
    address owner,
    address actor,
    address tokenAddress,
    uint256 tokenId,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation
  ) internal pure returns (bytes32) {
    return
      _hashBytes(
        abi.encode(
          keccak256(
            "Auth(bytes4 selector,address owner,address actor,address tokenAddress,uint256 tokenId,uint256 extra,uint256 extra2,uint256 extra3,uint256 timeValidation)"
          ),
          selector,
          owner,
          actor,
          tokenAddress,
          tokenId,
          extra,
          extra2,
          extra3,
          timeValidation
        )
      );
  }

  function _hashBytes(bytes memory signature) internal pure returns (bytes32 hash) {
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Load the data pointer of the `signature` bytes array
      let data := add(signature, 32) // Skip the length field
      // Load the length of the `signature` bytes array
      let length := mload(signature)
      // Perform the `keccak256` hash operation
      hash := keccak256(data, length)
    }
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
