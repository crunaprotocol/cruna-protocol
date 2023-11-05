// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

import {IProtected} from "./IProtected.sol";
import {IERC6454} from "./IERC6454.sol";
import {Actor, IActor} from "./Actor.sol";
import {Manager} from "./Manager.sol";

//import {console} from "hardhat/console.sol";

abstract contract Protected is
  IProtected,
  IERC6454,
  //  Actor,
  ERC721,
  Ownable2Step
{
  using ECDSA for bytes32;
  using Strings for uint256;

  mapping(uint256 => Manager) public managers;
  uint public nextTokenId;

  mapping(uint256 => bool) internal _approvedTransfers;

  //  modifier onlyProtectorFor(address owner_) {
  //    (uint256 i, IActor.Status status) = actorsManager.findProtector(owner_, _msgSender());
  //    if (status < IActor.Status.ACTIVE) revert NotAProtector();
  //    _;
  //  }

  modifier onlyProtectorForTokenId(uint256 tokenId_) {
    address owner_ = ownerOf(tokenId_);
    (uint256 i, IActor.Status status) = managers[tokenId_].findProtector(owner_, _msgSender());
    if (status < IActor.Status.ACTIVE) revert NotAProtector();
    _;
  }

  modifier onlyTokenOwner(uint256 tokenId) {
    //    console.log(_ownerOf(tokenId), _msgSender());
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

  function version() public pure returns (string memory) {
    return "1";
  }

  constructor(string memory name_, string memory symbol_, address actorsManager_) ERC721(name_, symbol_) {}

  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner(tokenId) {
    managers[tokenId].checkIfSignatureUsedAndUseIfNot(signature);
    managers[tokenId].isNotExpired(timestamp, validFor);
    address signer = managers[tokenId].recover(managers[tokenId].transferRequestDigest(to, timestamp, validFor), signature);
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
    _cleanOperators(tokenId);
    super._beforeTokenTransfer(from, to, tokenId, batchSize);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return interfaceId == type(IProtected).interfaceId || super.supportsInterface(interfaceId);
  }

  // safe recipients
  // must be overriden by the inheriting contract
  function _cleanOperators(uint256 tokenId) internal virtual;

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

  function _mintAndInit(address to) internal {
    // TODO use ERC6551Registry to create the Manager.sol
    // managers[nextTokenId] = new Manager.sol(name(), version(), nextTokenId);
    _safeMint(to, nextTokenId++);
  }
}
