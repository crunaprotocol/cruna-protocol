// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ICrunaGuardian} from "../utils/ICrunaGuardian.sol";
import {ICrunaRegistry} from "../utils/CrunaRegistry.sol";
import {ICrunaManaged} from "./ICrunaManaged.sol";
import {IERC6454} from "../interfaces/IERC6454.sol";
import {IERC6982} from "../interfaces/IERC6982.sol";
import {ICrunaManager} from "../manager/ICrunaManager.sol";
import {IVersioned} from "../utils/IVersioned.sol";

//import {console} from "hardhat/console.sol";

interface IVersionedManager {
  function version() external pure returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function DEFAULT_IMPLEMENTATION() external pure returns (address);
  function nameId() external pure returns (bytes4);
}

/**
 * @dev This contracts is a base for NFTs with protected transfers. It must be extended implementing
 *   the _canManage function to define who can alter the contract. Two versions are provided in this repo,
 *   CrunaManagedTimeControlled and CrunaManagedOwnable. The first is the recommended one, since it allows
 *   a governance aligned with best practices. The second is simpler, and can be used in
 *   less critical scenarios. If none of them fits your needs, you can implement your own policy.
 */
abstract contract CrunaManagedBase is ICrunaManaged, IVersioned, IERC6454, IERC6982, ERC721 {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address;

  error NotTransferable();
  error NotTheManager();
  error ZeroAddress();
  error RegistryNotFound();
  error AlreadyInitiated();
  error MaxSupplyReached();
  error ErrorCreatingManager();
  error NotTheTokenOwner();
  error CannotUpgradeToAnOlderVersion();
  error UntrustedImplementation();

  mapping(bytes32 => bool) public usedSignatures;
  ICrunaGuardian public guardian;
  ICrunaRegistry public registry;
  address public managerProxy;

  bytes4 public constant NAME_HASH = bytes4(keccak256("CrunaManaged"));

  uint256 public nextTokenId = 1;
  uint256 public maxTokenId;

  mapping(uint256 => bool) internal _approvedTransfers;

  // @dev This modifier will only allow the manager of a certain tokenId to call the function.
  // @param tokenId_ The id of the token.
  modifier onlyManager(uint256 tokenId) {
    if (managerOf(tokenId) != _msgSender()) revert NotTheManager();
    _;
  }

  function version() public pure virtual returns (uint256) {
    // semver 1.2.3 => 1002003 = 1e6 + 2e3 + 3
    return 1e6;
  }

  // @dev Constructor of the contract.
  // @param name_ The name of the token.
  // @param symbol_ The symbol of the token.
  // @param owner The address of the owner.
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    nextTokenId = 1;
    emit DefaultLocked(false);
  }

  // Must be overridden to specify who can manage changes in the contract states
  // It should revert it the caller is not allowed to manage
  // @param isInitializing True if the contract is being initialized, false otherwise
  //   During initialization, the caller is often the deployer, while later governance
  //   strategies can be applied (time lock, etc.).
  function _canManage(bool isInitializing) internal view virtual;

  function setMaxTokenId(uint256 maxTokenId_) external virtual {
    _canManage(maxTokenId == 0);
    if (nextTokenId > 0 && maxTokenId_ < nextTokenId - 1) maxTokenId_ = nextTokenId - 1;
    maxTokenId = maxTokenId_;
  }

  // @dev This function will initialize the contract.
  // @param registry_ The address of the registry contract.
  // @param guardian_ The address of the CrunaManager.sol guardian.
  // @param managerProxy_ The address of the manager proxy.
  function init(address registry_, address guardian_, address managerProxy_) external virtual {
    _canManage(true);
    // must be called immediately after deployment
    if (address(registry) != address(0)) revert AlreadyInitiated();
    if (registry_ == address(0) || guardian_ == address(0) || managerProxy_ == address(0)) revert ZeroAddress();
    guardian = ICrunaGuardian(guardian_);
    registry = ICrunaRegistry(registry_);
    managerProxy = managerProxy_;
  }

  function upgradeDefaultManager(address payable newManagerProxy) external virtual {
    _canManage(false);
    IVersionedManager newManager = IVersionedManager(newManagerProxy);
    if (guardian.trustedImplementation(newManager.nameId(), newManager.DEFAULT_IMPLEMENTATION()) == 0)
      revert UntrustedImplementation();
    if (newManager.version() <= IVersionedManager(managerProxy).version()) revert CannotUpgradeToAnOlderVersion();
    managerProxy = newManagerProxy;
    emit DefaultManagerUpgrade(newManagerProxy);
  }

  // @dev See {IProtected721-managedTransfer}.
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual override onlyManager(tokenId) {
    _approvedTransfers[tokenId] = true;
    _approve(managerOf(tokenId), tokenId, address(0));
    safeTransferFrom(ownerOf(tokenId), to, tokenId);
    _approve(address(0), tokenId, address(0));
    delete _approvedTransfers[tokenId];
    emit ManagedTransfer(pluginNameId, tokenId);
  }

  // @dev See {ERC721-_beforeTokenTransfer}.
  function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address) {
    if (isTransferable(tokenId, _ownerOf(tokenId), to)) {
      return super._update(to, tokenId, auth);
    } else revert NotTransferable();
  }

  // @dev See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721) returns (bool) {
    return
      interfaceId == type(ICrunaManaged).interfaceId ||
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
  function isTransferable(uint256 tokenId, address from, address to) public view virtual override returns (bool) {
    ICrunaManager manager = ICrunaManager(managerOf(tokenId));
    // Burnings and self transfers are not allowed
    if (to == address(0) || from == to) return false;
    // if from zero, it is minting
    else if (from == address(0)) return true;
    else {
      _requireOwned(tokenId);
      return manager.countActiveProtectors() == 0 || _approvedTransfers[tokenId] || manager.isSafeRecipient(to);
    }
  }

  // ERC6982

  function defaultLocked() external pure virtual override returns (bool) {
    return false;
  }

  // This function returns the lock status of a specific token.
  // If no Locked event has been emitted for a given tokenId, it MUST return
  // the value that defaultLocked() returns, which represents the default
  // lock status.
  // This function MUST revert if the token does not exist.
  function locked(uint256 tokenId) external view virtual override returns (bool) {
    return ICrunaManager(managerOf(tokenId)).hasProtectors();
  }

  // When a protector is set and the token becomes locked, this event must be emit
  // from the CrunaManager.sol
  function emitLockedEvent(uint256 tokenId, bool locked_) external virtual onlyManager(tokenId) {
    emit Locked(tokenId, locked_);
  }

  // We let the NFT emit the events, so that it is easier to listen to them
  function emitProtectorChangeEvent(
    uint256 tokenId,
    address protector,
    bool status,
    uint256 protectorsCount
  ) external virtual onlyManager(tokenId) {
    emit ProtectorChange(tokenId, protector, status);
    if (status && protectorsCount == 1) emit Locked(tokenId, true);
    else if (!status && protectorsCount == 0) emit Locked(tokenId, false);
  }

  function emitSafeRecipientChangeEvent(uint256 tokenId, address recipient, bool status) external virtual onlyManager(tokenId) {
    emit SafeRecipientChange(tokenId, recipient, status);
  }

  function emitPluginStatusChangeEvent(
    uint256 tokenId,
    string memory name,
    address plugin,
    bool status
  ) external virtual onlyManager(tokenId) {
    emit PluginStatusChange(tokenId, name, plugin, status);
  }

  function emitPluginAuthorizationChangeEvent(
    uint256 tokenId,
    string memory name,
    address plugin,
    bool status,
    uint256 lockTime
  ) external {
    emit PluginAuthorizationChange(tokenId, name, plugin, status, lockTime);
  }

  function emitResetEvent(uint256 tokenId) external virtual onlyManager(tokenId) onlyManager(tokenId) {
    emit Reset(tokenId);
  }

  // minting and initialization

  // @dev This function will mint a new token and initialize it.
  // @param to The address of the recipient.
  function _mintAndActivate(address to, bool alsoInit, uint256 amount) internal virtual {
    if (alsoInit && address(registry) == address(0)) revert RegistryNotFound();
    uint256 tokenId = nextTokenId;
    for (uint256 i = 0; i < amount; i++) {
      if (maxTokenId > 0 && tokenId > maxTokenId) revert MaxSupplyReached();
      if (alsoInit) {
        try registry.createBoundContract(managerProxy, 0x00, block.chainid, address(this), tokenId) {} catch {
          revert ErrorCreatingManager();
        }
      }
      _safeMint(to, tokenId++);
    }
    nextTokenId = tokenId;
  }

  function activate(uint256 tokenId) external virtual {
    if (_msgSender() != ownerOf(tokenId)) revert NotTheTokenOwner();
    if (address(registry) == address(0)) revert RegistryNotFound();
    try registry.createBoundContract(managerProxy, 0x00, block.chainid, address(this), tokenId) {} catch {
      revert ErrorCreatingManager();
    }
  }

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) public view virtual returns (address) {
    return registry.boundContract(managerProxy, 0x00, block.chainid, address(this), tokenId);
  }

  function isActive(uint256 tokenId) public view virtual returns (bool) {
    _requireOwned(tokenId);
    address _addr = managerOf(tokenId);
    uint32 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size > 0);
  }
}
