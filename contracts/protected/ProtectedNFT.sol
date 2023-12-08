// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {FlexiGuardian} from "../manager/FlexiGuardian.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {IProtected} from "../interfaces/IProtected.sol";
import {IERC6454} from "../interfaces/IERC6454.sol";
import {IERC6982} from "../interfaces/IERC6982.sol";
import {Manager} from "../manager/Manager.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {Versioned} from "../utils/Versioned.sol";

//import {console} from "hardhat/console.sol";

// @dev This contract is a base for NFTs with protected transfers.
abstract contract ProtectedNFT is IProtected, Versioned, IERC6454, IERC6982, ERC721, Ownable2Step {
  using ECDSA for bytes32;
  using Strings for uint256;

  error NotTheTokenOwner();
  error TimestampInvalidOrExpired();
  error SignatureAlreadyUsed();
  error NotTransferable();
  error NotTheManager();
  error TimestampZero();
  error ZeroAddress();
  error WrongDataOrNotSignedByProtector();
  error NotInitiated();
  error AlreadyInitiated();
  error OutOfRange();

  FlexiGuardian public guardian;
  SignatureValidator public validator;
  IERC6551Registry public registry;
  Manager public flexiProxy;

  bytes32 public salt = bytes32(uint256(400));

  mapping(uint256 => Manager) public managers;
  uint256 public nextTokenId = 1;

  mapping(uint256 => bool) internal _approvedTransfers;
  mapping(bytes32 => bool) public usedSignatures;

  // @dev This modifier will only allow the owner of a certain tokenId to call the function.
  // @param tokenId_ The id of the token.
  modifier onlyTokenOwner(uint256 tokenId) {
    if (ownerOf(tokenId) != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  // @dev This modifier will only allow the manager of a certain tokenId to call the function.
  // @param tokenId_ The id of the token.
  modifier onlyManager(uint256 tokenId) {
    if (address(managers[tokenId]) != _msgSender()) revert NotTheManager();
    _;
  }

  // @dev Constructor of the contract.
  // @param name_ The name of the token.
  // @param symbol_ The symbol of the token.
  // @param owner The address of the owner.
  constructor(string memory name_, string memory symbol_, address owner) ERC721(name_, symbol_) {
    if (owner == address(0)) revert ZeroAddress();
    _transferOwnership(owner);
    emit DefaultLocked(false);
    nextTokenId = block.chainid * 1e6 + 1;
  }

  // @dev This function will initialize the contract.
  // @param registry_ The address of the registry contract.
  // @param guardian_ The address of the Manager.sol guardian.
  // @param signatureValidator_ The address of the signature validator.
  // @param managerProxy_ The address of the manager proxy.
  function init(address registry_, address guardian_, address signatureValidator_, address managerProxy_) external onlyOwner {
    // must be called immediately after deployment
    if (address(validator) != address(0)) revert AlreadyInitiated();
    if (registry_ == address(0) || guardian_ == address(0) || signatureValidator_ == address(0) || managerProxy_ == address(0))
      revert ZeroAddress();
    guardian = FlexiGuardian(guardian_);
    validator = SignatureValidator(signatureValidator_);
    registry = IERC6551Registry(registry_);
    flexiProxy = Manager(managerProxy_);
  }

  // @dev See {IProtected721-protectedTransfer}.
  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner(tokenId) {
    if (timestamp == 0) revert TimestampZero();
    if (timestamp > block.timestamp || timestamp < block.timestamp - validFor) revert TimestampInvalidOrExpired();
    if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
    usedSignatures[keccak256(signature)] = true;
    address signer = validator.recoverSetActorSigner(
      keccak256("PROTECTED_TRANSFER"),
      _msgSender(),
      to,
      tokenId,
      0,
      timestamp,
      validFor,
      signature
    );
    if (!managers[tokenId].isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
    _approvedTransfers[tokenId] = true;
    _transfer(_msgSender(), to, tokenId);
    delete _approvedTransfers[tokenId];
  }

  // @dev See {IProtected721-managedTransfer}.
  function managedTransfer(uint256 tokenId, address to) external onlyManager(tokenId) {
    _approvedTransfers[tokenId] = true;
    _approve(address(managers[tokenId]), tokenId);
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
    _approve(address(0), tokenId);
    delete _approvedTransfers[tokenId];
  }

  // @dev See {ERC721-_beforeTokenTransfer}.
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override(ERC721) {
    if (isTransferable(tokenId, from, to)) {
      super._beforeTokenTransfer(from, to, tokenId, batchSize);
    } else revert NotTransferable();
  }

  // @dev See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == type(IProtected).interfaceId || super.supportsInterface(interfaceId);
  }

  // ERC6454

  // @dev Function to define a token as transferable or not, according to IERC6454
  // @param tokenId The id of the token.
  // @param from The address of the sender.
  // @param to The address of the recipient.
  // @return true if the token is transferable, false otherwise.
  function isTransferable(uint256 tokenId, address from, address to) public view override returns (bool) {
    // Burnings and self transfers are not allowed
    if (to == address(0) || from == to) return false;
    // if from zero, it is minting
    else if (from == address(0)) return true;
    else {
      _requireMinted(tokenId);
      return
        managers[tokenId].countActiveProtectors() == 0 || _approvedTransfers[tokenId] || managers[tokenId].isSafeRecipient(to);
    }
  }

  // ERC6982

  function defaultLocked() external pure override returns (bool) {
    return false;
  }

  // This function returns the lock status of a specific token.
  // If no Locked event has been emitted for a given tokenId, it MUST return
  // the value that defaultLocked() returns, which represents the default
  // lock status.
  // This function MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view override returns (bool) {
    return managers[tokenId].hasProtectors();
  }

  function emitLockedEvent(uint256 tokenId, bool locked_) external onlyManager(tokenId) {
    emit Locked(tokenId, locked_);
  }

  // minting and initialization

  // @dev This function will mint a new token and initialize it.
  // @param to The address of the recipient.
  function _mintAndInit(address to) internal {
    //    if (!(nextTokenId % 1e6)) revert OutOfRange();
    if (address(registry) == address(0)) revert NotInitiated();
    registry.createAccount(address(flexiProxy), salt, block.chainid, address(this), nextTokenId);
    managers[nextTokenId] = Manager(managerOf(nextTokenId));
    _safeMint(to, nextTokenId++);
  }

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) public view returns (address) {
    return registry.account(address(flexiProxy), salt, block.chainid, address(this), tokenId);
  }
}
