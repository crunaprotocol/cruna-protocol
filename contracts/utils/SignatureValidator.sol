// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {ISignatureValidator} from "./ISignatureValidator.sol";
import {ICrunaManager} from "../manager/ICrunaManager.sol";

/**
 * @title SignatureValidator
 * @author Francesco Sullo <francesco@sullo.co>
 * @notice This contract is used to validate signatures.
 * It is based on EIP712 and supports typed messages V4.
 */
abstract contract SignatureValidator is ISignatureValidator, EIP712, Context {
  using ECDSA for bytes32;

  /**
   * @notice The time validation is a uint256 with the following structure:
   * - the timestamp is multiplied by 10_000_000
   * - the validity is added to the timestamp
   * For example, if timestamp is 1710280592 and validFor is 3600
   * the timeValidation will be 17102805920003600
   */

  /**
   * @notice The maximum validFor. If more than this it will conflict with the timestamp.
   */
  uint256 internal constant _MAX_VALID_FOR = 9_999_999;

  /**
   * @notice The multiplier for the timestamp in the timeValidation parameter.
   */
  uint256 internal constant _TIMESTAMP_MULTIPLIER = 10_000_000;

  /**
   * @notice All the pre approvals
   * - operationsHash The hash of operations
   * - approver The protector approving it
   */
  mapping(bytes32 operationsHash => address approver) private _preApprovals;

  /**
   * @notice All the used signatures
   * - signatureHash The hash of the signature
   * - used 1 if the signature has been use, 0 (default) if not
   */
  mapping(bytes32 signatureHash => uint256 used) private _usedSignatures;

  /**
   * @notice EIP712 constructor
   */
  constructor() EIP712("Cruna", "1") payable {}

  /// @dev see {ISignatureValidator-preApprovals}
  function preApprovals(bytes32 hash) external view override returns (address) {
    return _preApprovals[hash];
  }

  /// @dev see {ISignatureValidator-hashSignature}
  function hashSignature(bytes calldata signature) external pure override returns (bytes32) {
    return _hashBytes(signature);
  }

  /// @dev see {ISignatureValidator-isSignatureUsed}
  function isSignatureUsed(bytes32 hash) external view override returns (bool) {
    return _usedSignatures[hash] == 1;
  }

  /// @dev see {ISignatureValidator-recoverSigner}
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
    uint256 timestamp = timeValidation / _TIMESTAMP_MULTIPLIER;
    if (timestamp != 0)
      if (timestamp > block.timestamp || timestamp < block.timestamp - (timeValidation % _TIMESTAMP_MULTIPLIER))
        revert TimestampInvalidOrExpired();
    bytes32 hash = _hashData(selector, owner, actor, tokenAddress, tokenId, extra, extra2, extra3, timeValidation);
    if (65 == signature.length) {
      return (_hashTypedDataV4(hash).recover(signature), hash);
    }
    return (_preApprovals[hash], hash);
  }

  /// @dev see {ISignatureValidator-preApprove}
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

  /**
   * @notice Checks if someone can pre approve an operation.
   * Must be implemented by the contract using this base contract
   * @param selector The selector of the function being called.
   * @param actor The actor being authorized.
   * @param signer The signer of the operation (the protector)
   */
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual returns (bool);

  /**
   * @notice Checks if the NFT is protected.
   * Must be implemented by the contract using this base contract
   */
  function _isProtected() internal view virtual returns (bool);

  /**
   * @notice Checks if an address is a protector.
   * Must be implemented by the contract using this base contract
   */
  function _isProtector(address protector) internal view virtual returns (bool);

  /**
   * @notice Validates and checks the signature.
   * @param selector The selector of the function being called.
   * @param owner The owner of the token.
   * @param actor The actor being authorized.
   * @param tokenAddress The address of the token.
   * @param tokenId The id of the token.
   * @param extra The extra
   * @param extra2 The extra2
   * @param extra3 The extra3
   * @param timeValidation A combination of timestamp and validity of the signature.
   * @param signature The signature.
   */
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
    uint256 timeValidation,
    bytes calldata signature
  ) internal virtual {
    if (timeValidation < _TIMESTAMP_MULTIPLIER) {
      if (_isProtected()) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (_usedSignatures[_hashBytes(signature)] == 1) revert SignatureAlreadyUsed();
      _usedSignatures[_hashBytes(signature)] = 1;
      (address signer, bytes32 hash) = recoverSigner(
        selector,
        owner,
        actor,
        tokenAddress,
        tokenId,
        extra,
        extra2,
        extra3,
        timeValidation,
        signature
      );
      if (selector == ICrunaManager.setProtector.selector && !_isProtected()) {
        if (signer != actor) revert WrongDataOrNotSignedByProtector();
      } else if (!_isProtector(signer)) revert WrongDataOrNotSignedByProtector();
      delete _preApprovals[hash];
    }
  }

  /**
   * @notice Hashes the data.
   * @param selector The selector of the function being called.
   * @param owner The owner of the token.
   * @param actor The actor being authorized.
   * @param tokenAddress The address of the token.
   * @param tokenId The id of the token.
   * @param extra The extra
   * @param extra2 The extra2
   * @param extra3 The extra3
   * @param timeValidation A combination of timestamp and validity of the signature.
   */
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

  /**
   * @notice Util to hash the bytes of the signature saving gas in comparison with using keccak256.
   * @param signature The signature.
   */
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
