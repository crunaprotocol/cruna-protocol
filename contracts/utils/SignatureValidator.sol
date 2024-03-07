// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

//import "hardhat/console.sol";

// @dev This contract is used to validate signatures.
//   It is based on EIP712 and supports typed messages V4.
abstract contract SignatureValidator is EIP712, Context {
  using ECDSA for bytes32;

  event PreApproved(bytes32 hash, address indexed signer);

  error TimestampInvalidOrExpired();
  error NotAuthorized();
  error NotPermittedWhenProtectorsAreActive();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();

  mapping(bytes32 => address) public preApprovals;
  mapping(bytes32 => bool) public usedSignatures;

  constructor() EIP712("Cruna", "1") {}

  // must be implemented by managers and plugins
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool);

  function _validate(uint256 timeValidation) internal view {
    uint256 timestamp = timeValidation / 1e7;
    if (timestamp > block.timestamp || timestamp < block.timestamp - (timeValidation % 1e7)) revert TimestampInvalidOrExpired();
  }

  function _isProtected() internal view virtual returns (bool);

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
    if (timeValidationAndSetProtector < 1e17 && timeValidationAndSetProtector % 1e17 < 1e7) {
      if (_isProtected()) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      usedSignatures[keccak256(signature)] = true;
      (address signer, bytes32 hash) = recoverSigner(
        selector,
        owner,
        actor,
        tokenAddress,
        tokenId,
        extra,
        extra2,
        extra3,
        timeValidationAndSetProtector % 1e17,
        signature
      );
      if (timeValidationAndSetProtector > 1e17 && !_isProtected()) {
        if (signer != actor) revert WrongDataOrNotSignedByProtector();
      } else if (!_isProtector(signer)) revert WrongDataOrNotSignedByProtector();
      delete preApprovals[hash];
    }
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
  //     timestamp * 1e7 + validity
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
  ) public view returns (address, bytes32) {
    _validate(timeValidation);
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    if (signature.length == 65) {
      return (_hashTypedDataV4(hash).recover(signature), hash);
    } else {
      return (preApprovals[hash], hash);
    }
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
  ) external {
    if (!_canPreApprove(selector, actor, _msgSender())) revert NotAuthorized();
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    preApprovals[hash] = _msgSender();
    emit PreApproved(hash, _msgSender());
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
      keccak256(
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

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
