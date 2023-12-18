// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Guardian} from "../manager/Guardian.sol";
import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {IManagedERC721} from "../interfaces/IManagedERC721.sol";
import {IERC6454} from "../interfaces/IERC6454.sol";
import {IERC6982} from "../interfaces/IERC6982.sol";
import {Manager} from "../manager/Manager.sol";
import {Versioned} from "../utils/Versioned.sol";

//import {console} from "hardhat/console.sol";

// @dev This contract is a base for NFTs with protected transfers.
abstract contract ManagedERC721 is IManagedERC721, Versioned, IERC6454, IERC6982, ERC721, Ownable2Step {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address;

  event ManagedTransfer(bytes4 indexed pluginNameHash, uint256 indexed tokenId);

  error NotTransferable();
  error NotTheManager();
  error ZeroAddress();
  error RegistryNotFound();
  error AlreadyInitiated();
  error SupplyCapReached();
  error ErrorCreatingManager();
  error NotTheTokenOwner();

  mapping(bytes32 => bool) public usedSignatures;
  Guardian public guardian;
  ICrunaRegistry public registry;
  Manager public managerProxy;

  bytes32 public constant SALT = bytes32(uint256(69));
  bytes4 public constant NAME_HASH = bytes4(keccak256("ManagedNFT"));

  uint256 public nextTokenId = 1;

  mapping(uint256 => bool) internal _approvedTransfers;

  // @dev This modifier will only allow the manager of a certain tokenId to call the function.
  // @param tokenId_ The id of the token.
  modifier onlyManager(uint256 tokenId) {
    if (managerOf(tokenId) != _msgSender()) revert NotTheManager();
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
    nextTokenId = block.chainid * 1e8 + version() * 1e6 + 1;
  }

  // @dev This function will initialize the contract.
  // @param registry_ The address of the registry contract.
  // @param guardian_ The address of the Manager.sol guardian.
  // @param managerProxy_ The address of the manager proxy.
  function init(address registry_, address guardian_, address managerProxy_) external onlyOwner {
    // must be called immediately after deployment
    if (address(registry) != address(0)) revert AlreadyInitiated();
    if (registry_ == address(0) || guardian_ == address(0) || managerProxy_ == address(0)) revert ZeroAddress();
    guardian = Guardian(guardian_);
    registry = ICrunaRegistry(registry_);
    managerProxy = Manager(managerProxy_);
  }

  // @dev See {IProtected721-managedTransfer}.
  function managedTransfer(bytes4 pluginNameHash, uint256 tokenId, address to) external override onlyManager(tokenId) {
    _approvedTransfers[tokenId] = true;
    _approve(managerOf(tokenId), tokenId);
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
    _approve(address(0), tokenId);
    delete _approvedTransfers[tokenId];
    emit ManagedTransfer(pluginNameHash, tokenId);
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
    return
      interfaceId == type(IManagedERC721).interfaceId ||
      interfaceId == type(IERC6454).interfaceId ||
      interfaceId == type(IERC6982).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  // ERC6454

  // @dev Function to define a token as transferable or not, according to IERC6454
  // @param tokenId The id of the token.
  // @param from The address of the sender.
  // @param to The address of the recipient.
  // @return true if the token is transferable, false otherwise.
  function isTransferable(uint256 tokenId, address from, address to) public view override returns (bool) {
    Manager manager = Manager(managerOf(tokenId));
    // Burnings and self transfers are not allowed
    if (to == address(0) || from == to) return false;
    // if from zero, it is minting
    else if (from == address(0)) return true;
    else {
      _requireMinted(tokenId);
      return manager.countActiveProtectors() == 0 || _approvedTransfers[tokenId] || manager.isSafeRecipient(to);
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
    return Manager(managerOf(tokenId)).hasProtectors();
  }

  // When a protector is set and the token becomes locked, this event must be emit
  // from the Manager
  function emitLockedEvent(uint256 tokenId, bool locked_) external onlyManager(tokenId) {
    emit Locked(tokenId, locked_);
  }

  // minting and initialization

  // @dev This function will mint a new token and initialize it.
  // @param to The address of the recipient.
  function _mintAndActivate(address to, bool alsoInit, uint256 amount) internal {
    if (alsoInit && address(registry) == address(0)) revert RegistryNotFound();
    uint256 tokenId = nextTokenId;
    for (uint256 i = 0; i < amount; i++) {
      // the max supply is 999,999
      if (tokenId % 1e6 == 0) revert SupplyCapReached();
      if (alsoInit) {
        try registry.createBoundContract(address(managerProxy), SALT, block.chainid, address(this), tokenId) {} catch {
          revert ErrorCreatingManager();
        }
      }
      _safeMint(to, tokenId++);
    }
    nextTokenId += amount;
  }

  function activate(uint256 tokenId) external {
    if (_msgSender() != ownerOf(tokenId)) revert NotTheTokenOwner();
    if (address(registry) == address(0)) revert RegistryNotFound();
    try registry.createBoundContract(address(managerProxy), SALT, block.chainid, address(this), tokenId) {} catch {
      revert ErrorCreatingManager();
    }
  }

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) public view returns (address) {
    return registry.bondContract(address(managerProxy), SALT, block.chainid, address(this), tokenId);
  }

  function isActive(uint256 tokenId) public view returns (bool) {
    _requireMinted(tokenId);
    address proxy = managerOf(tokenId);
    return proxy.isContract();
  }
}
