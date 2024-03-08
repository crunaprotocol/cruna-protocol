// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>
//
import {IERC165, ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC6551AccountLib} from "erc6551/lib/ERC6551AccountLib.sol";

import {IManagedNFT, ICrunaProtectedNFT} from "./ICrunaProtectedNFT.sol";
import {IERC6454} from "../interfaces/IERC6454.sol";
import {IERC6982} from "../interfaces/IERC6982.sol";
import {ICrunaManager} from "../manager/ICrunaManager.sol";
import {IVersioned} from "../utils/IVersioned.sol";
import {CanonicalAddresses} from "../canonical/CanonicalAddresses.sol";

// import {console} from "hardhat/console.sol";

interface IVersionedManager {
  function version() external pure returns (uint256);

  // solhint-disable-next-line func-name-mixedcase
  function DEFAULT_IMPLEMENTATION() external pure returns (address);
  function nameId() external pure returns (bytes4);
}

/**
 * @dev This contracts is a base for NFTs with protected transfers. It must be extended implementing
 * the _canManage function to define who can alter the contract. Two versions are provided in this repo,CrunaProtectedNFTTimeControlled.sol and CrunaProtectedNFTOwnable.sol. The first is the recommended one, since it allows a governance aligned with best practices. The second is simpler, and can be used in less critical scenarios. If none of them fits your needs, you can implement your own policy.
 */
abstract contract CrunaProtectedNFT is ICrunaProtectedNFT, IVersioned, CanonicalAddresses, IERC6454, IERC6982, ERC721 {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address;

  bytes4 public constant NAME_HASH = 0xbe6d302d; // bytes4(keccak256("CrunaProtectedNFT"));

  NftConf public nftConf;
  ManagerHistory[] public managerHistory;

  /**
   * @dev internal variable used to make protected NFT temporarily transferable.
   * It is set before the transfer and removed after it, during the manager transfer process.
   */
  mapping(uint256 => bool) internal _approvedTransfers;

  /**
   * @dev This modifier will only allow the manager of a certain tokenId to call the function.
   */
  modifier onlyManagerOf(uint256 tokenId) {
    if (managerOf(tokenId) != _msgSender()) revert NotTheManager();
    _;
  }

  function version() public pure virtual returns (uint256) {
    // semver 1.2.3 => 1002003 = 1e6 + 2e3 + 3
    return 1_000_000;
  }

  // @dev Constructor of the contract.
  constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
    emit DefaultLocked(false);
  }

  /**
   * @dev Initializes the NFT. It MUST be called before doing anything else
   * @notice A wrong configuration can make the NFT unusable.
   * If you need special configurations, override this function. For this case, we keep the tokenId params as uint256 to provide more flexibility
   */
  function init(
    address managerAddress_,
    bool progressiveTokenIds_,
    bool allowUntrustedTransfers_,
    uint112 nextTokenId_,
    uint112 maxTokenId_
  ) external virtual override {
    _canManage(true);
    if (nftConf.managerHistoryLength != 0) revert AlreadyInitiated();
    if (managerAddress_ == address(0)) revert ZeroAddress();
    nftConf = NftConf({
      progressiveTokenIds: progressiveTokenIds_,
      allowUntrustedTransfers: allowUntrustedTransfers_,
      nextTokenId: nextTokenId_,
      maxTokenId: maxTokenId_,
      managerHistoryLength: 1,
      unusedField: 0
    });
    managerHistory.push(ManagerHistory({managerAddress: managerAddress_, firstTokenId: nextTokenId_, lastTokenId: 0}));
  }

  function allowUntrustedTransfers() external view virtual override returns (bool) {
    return nftConf.allowUntrustedTransfers;
  }

  function setMaxTokenId(uint112 maxTokenId_) external virtual {
    _canManage(nftConf.maxTokenId == 0);
    if (maxTokenId_ == 0) revert InvalidMaxTokenId();
    if (nftConf.progressiveTokenIds && nftConf.nextTokenId > maxTokenId_ + 1) revert InvalidMaxTokenId();
    nftConf.maxTokenId = maxTokenId_;
  }

  function defaultManagerImplementation(uint256 _tokenId) public view virtual override returns (address) {
    if (nftConf.managerHistoryLength == 1) return managerHistory[0].managerAddress;
    for (uint256 i; i < nftConf.managerHistoryLength; i++) {
      if (
        _tokenId >= managerHistory[i].firstTokenId &&
        (managerHistory[i].lastTokenId == 0 || _tokenId <= managerHistory[i].lastTokenId)
      ) return managerHistory[i].managerAddress;
    }
    // should never happen
    return address(0);
  }

  function upgradeDefaultManager(address payable newManagerProxy) external virtual {
    _canManage(false);
    if (!nftConf.progressiveTokenIds) revert NotAvailableIfTokenIdsAreNotProgressive();
    IVersionedManager newManager = IVersionedManager(newManagerProxy);
    if (_crunaGuardian().trustedImplementation(newManager.nameId(), newManager.DEFAULT_IMPLEMENTATION()) == 0)
      revert UntrustedImplementation();
    address lastEmitter = managerHistory[nftConf.managerHistoryLength - 1].managerAddress;
    if (newManager.version() <= IVersionedManager(lastEmitter).version()) revert CannotUpgradeToAnOlderVersion();
    managerHistory[nftConf.managerHistoryLength - 1].lastTokenId = nftConf.nextTokenId - 1;
    managerHistory.push(ManagerHistory({managerAddress: newManagerProxy, firstTokenId: nftConf.nextTokenId, lastTokenId: 0}));
    nftConf.managerHistoryLength++;
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

  // @dev See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
    return
      interfaceId == type(IManagedNFT).interfaceId ||
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
    if (from == address(0)) return true;
    _requireOwned(tokenId);
    return manager.isTransferable(to) || _approvedTransfers[tokenId];
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

  /**
   * @dev Emit a Locked event when a protector is set and the token becomes locked.
   * This function is not virtual because if overridden, it may consume more gas than the gas sent by the manager.
   */
  function emitLockedEvent(uint256 tokenId, bool locked_) external onlyManagerOf(tokenId) {
    emit Locked(tokenId, locked_);
  }

  function deployPlugin(
    address pluginImplementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external virtual override onlyManagerOf(tokenId) returns (address) {
    return _deploy(pluginImplementation, salt, tokenId, isERC6551Account);
  }

  function isDeployed(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) external view virtual returns (bool) {
    address _addr = _addressOfDeployed(implementation, salt, tokenId, isERC6551Account);
    uint32 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(_addr)
    }
    return (size != 0);
  }

  // @dev This function will return the address of the manager for tokenId.
  // @param tokenId The id of the token.
  function managerOf(uint256 tokenId) public view virtual returns (address) {
    return _addressOfDeployed(defaultManagerImplementation(tokenId), 0x00, tokenId, false);
  }

  function _addressOfDeployed(
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

  /**
   * @dev Must be overridden to specify who can manage changes during initialization and later
   */
  function _canManage(bool isInitializing) internal view virtual;

  // @dev See {ERC721-_beforeTokenTransfer}.
  function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721) returns (address) {
    if (isTransferable(tokenId, _ownerOf(tokenId), to)) {
      return super._update(to, tokenId, auth);
    }
    revert NotTransferable();
  }

  // @dev This function will mint a new token and initialize it if progressiveTokenIds is true.
  function _mintAndActivateByAmount(address to, uint256 amount) internal virtual {
    if (!nftConf.progressiveTokenIds) revert NotAvailableIfTokenIdsAreNotProgressive();
    if (nftConf.managerHistoryLength == 0) revert NftNotInitiated();
    uint256 tokenId = nftConf.nextTokenId;
    for (uint256 i; i < amount; i++) {
      _mintAndActivate(to, tokenId++);
    }
    nftConf.nextTokenId = uint112(tokenId);
  }

  // @dev This function will mint a new token and initialize it.
  // Use it carefully if nftConf.progressiveTokenIds is true.
  function _mintAndActivate(address to, uint256 tokenId) internal virtual {
    if (nftConf.managerHistoryLength == 0) revert NftNotInitiated();
    if (
      tokenId > type(uint112).max ||
      (nftConf.maxTokenId != 0 && tokenId > nftConf.maxTokenId) ||
      (tokenId < managerHistory[0].firstTokenId)
    ) revert InvalidTokenId();
    _deploy(defaultManagerImplementation(tokenId), 0x00, tokenId, false);
    _safeMint(to, tokenId++);
  }

  function _deploy(
    address implementation,
    bytes32 salt,
    uint256 tokenId,
    bool isERC6551Account
  ) internal virtual returns (address) {
    if (isERC6551Account) {
      return _erc6551Registry().createAccount(implementation, salt, block.chainid, address(this), tokenId);
    }
    return _crunaRegistry().createTokenLinkedContract(implementation, salt, block.chainid, address(this), tokenId);
  }
}
