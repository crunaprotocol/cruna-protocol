// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {IERC165, ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {ICrunaPlugin} from "../plugins/ICrunaPlugin.sol";
import {ICrunaManagedNFT} from "./ICrunaManagedNFT.sol";
import {IERC6454} from "../interfaces/IERC6454.sol";
import {IERC6982} from "../interfaces/IERC6982.sol";
import {ICrunaManager} from "../manager/ICrunaManager.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {CanonicalAddresses} from "../canonical/CanonicalAddresses.sol";

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
 *   CrunaManagedNFTTimeControlled.sol and CrunaManagedNFTOwnable.sol. The first is the recommended one, since it allows
 *   a governance aligned with best practices. The second is simpler, and can be used in
 *   less critical scenarios. If none of them fits your needs, you can implement your own policy.
 */
abstract contract CrunaManagedNFTBase is ICrunaManagedNFT, CanonicalAddresses, IVersioned, IERC6454, IERC6982, ERC721 {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address;

  error NotTransferable();
  error NotTheManager();
  error ZeroAddress();
  error RegistryNotFound();
  error AlreadyInitiated();
  error SupplyOverflow();
  error ErrorCreatingManager();
  error NotTheTokenOwner();
  error CannotUpgradeToAnOlderVersion();
  error UntrustedImplementation();
  error InvalidNextTokenId();

  // this is supposed to be a small array, ideally with a single element
  mapping(uint256 => ManagerHistory) public managerHistory;
  uint256 public managerHistoryLength;

  bytes4 public constant NAME_HASH = bytes4(keccak256("CrunaManagedNFT"));

  uint256 public nextTokenId = 1;
  uint256 public maxTokenId;

  // used by the manager to approve transfers during development
  bool public deployedToProduction;

  mapping(uint256 => bool) internal _approvedTransfers;

  // @dev This modifier will only allow the manager of a certain tokenId to call the function.
  // @param tokenId_ The id of the token.
  modifier onlyManagerOf(uint256 tokenId) {
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

  function init(address managerProxy_, uint256 firstTokenId_, bool deployedToProduction_) external virtual {
    _canManage(true);
    // must be called immediately after deployment
    if (managerHistoryLength > 0) revert AlreadyInitiated();
    if (managerProxy_ == address(0)) revert ZeroAddress();
    if (firstTokenId_ == 0) revert InvalidNextTokenId();
    managerHistory[0] = ManagerHistory({managerAddress: managerProxy_, firstTokenId: firstTokenId_, lastTokenId: 0});
    managerHistoryLength = 1;
    nextTokenId = firstTokenId_;
    // Since there is no way to know if a chain is a testnet, it is the deployer responsibility to set this flag correctly.
    // Be careful. Setting a mainnet token as a testnet token introduces severe security issues
    deployedToProduction = deployedToProduction_;
  }

  function defaultManagerImplementation(uint256 _tokenId) public view virtual override returns (address) {
    if (managerHistoryLength == 1) return managerHistory[0].managerAddress;
    else {
      for (uint256 i = 0; i < managerHistoryLength; i++) {
        if (
          _tokenId >= managerHistory[i].firstTokenId &&
          (managerHistory[i].lastTokenId == 0 || _tokenId <= managerHistory[i].lastTokenId)
        ) return managerHistory[i].managerAddress;
      }
    }
    // should never happen
    return address(0);
  }

  function upgradeDefaultManager(address payable newManagerProxy) external virtual {
    _canManage(false);
    IVersionedManager newManager = IVersionedManager(newManagerProxy);
    if (_crunaGuardian().trustedImplementation(newManager.nameId(), newManager.DEFAULT_IMPLEMENTATION()) == 0)
      revert UntrustedImplementation();
    address lastEmitter = managerHistory[managerHistoryLength - 1].managerAddress;
    if (newManager.version() <= IVersionedManager(lastEmitter).version()) revert CannotUpgradeToAnOlderVersion();
    managerHistory[managerHistoryLength - 1].lastTokenId = nextTokenId - 1;
    managerHistory[managerHistoryLength++] = ManagerHistory({
      managerAddress: newManagerProxy,
      firstTokenId: nextTokenId,
      lastTokenId: 0
    });
    emit DefaultManagerUpgrade(newManagerProxy);
  }

  // @dev See {IProtected721-managedTransfer}.
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual override onlyManagerOf(tokenId) {
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
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
    return
      interfaceId == type(ICrunaManagedNFT).interfaceId ||
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
      return manager.isTransferable(to) || _approvedTransfers[tokenId];
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
    return ICrunaManager(managerOf(tokenId)).locked();
  }

  // When a protector is set and the token becomes locked, this event must be emit
  // from the CrunaManager.sol
  function emitLockedEvent(uint256 tokenId, bool locked_) external virtual onlyManagerOf(tokenId) {
    emit Locked(tokenId, locked_);
  }

  // minting and initialization

  // @dev This function will mint a new token and initialize it.
  // @param to The address of the recipient.
  function _mintAndActivate(address to, uint256 amount) internal virtual {
    uint256 tokenId = nextTokenId;
    for (uint256 i = 0; i < amount; i++) {
      if (maxTokenId > 0 && tokenId > maxTokenId) revert SupplyOverflow();
      _deploy(defaultManagerImplementation(tokenId), 0x00, tokenId, false);
      _safeMint(to, tokenId++);
    }
    nextTokenId = tokenId;
  }

  function _deploy(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) internal virtual returns (address) {
    if (isERC6551Account) {
      return _erc6551Registry().createAccount(implementation, salt, block.chainid, address(this), tokenId);
    } else {
      return _crunaRegistry().createTokenLinkedContract(implementation, salt, block.chainid, address(this), tokenId);
    }
  }

  function deployPlugin(
    address pluginImplementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external virtual override onlyManagerOf(tokenId) returns (address) {
    address plugin = _deploy(pluginImplementation, salt, tokenId, isERC6551Account);
    // this will revert if already initiated
    ICrunaPlugin(plugin).initManager();
    return plugin;
  }

  //  function isPluginDeployed(address implementation, bytes32 salt, uint256 tokenId, bool isERC6551Account) external view virtual returns(bool) {
  //    address _addr = _addressOfPlugin(implementation, salt, tokenId, isERC6551Account);
  //    uint32 size;
  //    // solhint-disable-next-line no-inline-assembly
  //    assembly {
  //      size := extcodesize(_addr)
  //    }
  //    return (size > 0);
  //  }

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) public view virtual returns (address) {
    return
      ERC6551AccountLib.computeAddress(
        address(_crunaRegistry()),
        defaultManagerImplementation(tokenId),
        0x00,
        block.chainid,
        address(this),
        tokenId
      );
  }

  function _addressOfPlugin(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) internal view virtual returns (address) {
    return
      ERC6551AccountLib.computeAddress(
        isERC6551Account ? address(_erc6551Registry()) : address(_crunaRegistry()),
        implementation,
        salt,
        block.chainid,
        address(this),
        tokenId
      );
  }

}
