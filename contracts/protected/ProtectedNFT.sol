// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IAccountGuardian} from "@tokenbound/contracts/interfaces/IAccountGuardian.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {IProtected} from "./IProtected.sol";
import {IERC6454} from "./IERC6454.sol";
import {IActor} from "../manager/Actor.sol";
import {Manager} from "../manager/Manager.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";
import {ManagerProxy} from "../manager/ManagerProxy.sol";
import {Versioned} from "../utils/Versioned.sol";

//import {console} from "hardhat/console.sol";

error NotTheTokenOwner();
error NotAProtector();
error NotATokensOwner();
error TimestampInvalidOrExpired();
error SignatureAlreadyUsed();
error NotTransferable();
error NotTheManager();
error TimestampZero();
error AlreadyInitialized();
error NoZeroAddress();

abstract contract ProtectedNFT is IProtected, Versioned, IERC6454, ERC721, Ownable2Step, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;

  IAccountGuardian public immutable GUARDIAN;
  SignatureValidator public immutable VALIDATOR;
  IERC6551Registry public immutable REGISTRY;
  Manager public immutable MANAGER;
  ManagerProxy public immutable MANAGER_PROXY;

  bytes32 public salt = keccak256("Cruna_Manager");

  mapping(uint256 => Manager) public managers;
  uint256 public nextTokenId;

  mapping(uint256 => bool) internal _approvedTransfers;
  mapping(bytes32 => bool) public usedSignatures;

  modifier onlyProtectorForTokenId(uint256 tokenId_) {
    address owner_ = ownerOf(tokenId_);
    (uint256 i, IActor.Status status) = managers[tokenId_].findProtector(owner_, _msgSender());
    if (status < IActor.Status.ACTIVE) revert NotAProtector();
    _;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    if (ownerOf(tokenId) != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  modifier onlyManager(uint256 tokenId) {
    if (address(managers[tokenId]) != _msgSender()) revert NotTheManager();
    _;
  }

  modifier onlyTokensOwner() {
    if (balanceOf(_msgSender()) == 0) revert NotATokensOwner();
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    address registry_,
    address guardian_,
    address signatureValidator_,
    address manager_,
    address managerProxy_
  ) ERC721(name_, symbol_) {
    if (
      registry_ == address(0) ||
      guardian_ == address(0) ||
      signatureValidator_ == address(0) ||
      manager_ == address(0) ||
      managerProxy_ == address(0)
    ) revert NoZeroAddress();
    GUARDIAN = IAccountGuardian(guardian_);
    VALIDATOR = SignatureValidator(signatureValidator_);
    REGISTRY = IERC6551Registry(registry_);
    MANAGER = Manager(manager_);
    MANAGER_PROXY = ManagerProxy(payable(managerProxy_));
  }

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
    address signer = managers[tokenId].signatureValidator().recoverSigner2(
      _msgSender(),
      to,
      tokenId,
      0,
      timestamp,
      validFor,
      signature
    );
    managers[tokenId].isSignerAProtector(ownerOf(tokenId), signer);
    _approvedTransfers[tokenId] = true;
    _transfer(_msgSender(), to, tokenId);
    delete _approvedTransfers[tokenId];
  }

  function managedTransfer(uint256 tokenId, address to) external override onlyManager(tokenId) {
    _approvedTransfers[tokenId] = true;
    _approve(address(managers[tokenId]), tokenId);
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
    _transfer(ownerOf(tokenId), to, tokenId);
    delete _approvedTransfers[tokenId];
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId,
    uint256 batchSize
  ) internal virtual override(ERC721) {
    if (!isTransferable(tokenId, from, to)) revert NotTransferable();
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == type(IProtected).interfaceId || super.supportsInterface(interfaceId);
  }

  // IERC6454

  function isTransferable(uint256 tokenId, address from, address to) public view override returns (bool) {
    // Burnings and self transfers are not allowed
    if (to == address(0) || from == to) return false;
    // if from zero, it is minting
    else if (from == address(0)) return true;
    else {
      _requireMinted(tokenId);
      return
        managers[tokenId].countActiveProtectors(ownerOf(tokenId)) == 0 ||
        _approvedTransfers[tokenId] ||
        managers[tokenId].safeRecipientLevel(ownerOf(tokenId), to) == IActor.Level.HIGH;
    }
  }

  // minting new token binding the manager to it

  function _mintAndInit(address to) internal {
    REGISTRY.createAccount(address(MANAGER_PROXY), salt, block.chainid, address(MANAGER), nextTokenId);
    // managers[nextTokenId] = new Manager.sol(name(), version(), nextTokenId);
    _safeMint(to, nextTokenId++);
  }
}
