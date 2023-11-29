// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.19;

// Author: Francesco Sullo <francesco@sullo.co>

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {IERC6551Registry} from "erc6551/interfaces/IERC6551Registry.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";

import {Guardian} from "./Guardian.sol";
import {ProtectedNFT} from "../protected/ProtectedNFT.sol";
import {Actor} from "./Actor.sol";
import {IManager} from "./IManager.sol";
import {Versioned} from "../utils/Versioned.sol";
import {IPlugin} from "../plugins/IPlugin.sol";
import {ManagerBase} from "./ManagerBase.sol";

//import {console} from "hardhat/console.sol";

contract Manager is IManager, Actor, Context, Versioned, UUPSUpgradeable, ManagerBase {
  using ECDSA for bytes32;
  using Strings for uint256;

  error TimestampZero();
  error Forbidden();
  error NotTheTokenOwner();
  error ProtectorNotFound();
  error ProtectorAlreadySetByYou();
  error NotPermittedWhenProtectorsAreActive();
  error TimestampInvalidOrExpired();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();
  error CannotBeYourself();
  error InvalidImplementation();
  error NotTheInheritanceManager();
  error PluginAlreadyPlugged();
  error RoleNotFound();

  bool public constant IS_MANAGER = true;
  bool public constant IS_NOT_MANAGER = false;

  bytes32 public constant PROTECTOR = keccak256(abi.encodePacked("PROTECTOR"));
  bytes32 public constant SENTINEL = keccak256(abi.encodePacked("SENTINEL"));
  bytes32 public constant SAFE_RECIPIENT = keccak256(abi.encodePacked("SAFE_RECIPIENT"));

  Guardian public guardian;
  IERC6551Registry public registry;
  SignatureValidator public signatureValidator;
  ProtectedNFT public vault;

  mapping(bytes32 => IPlugin) public plugins;
  mapping(bytes32 => bytes32) public pluginByRole;
  mapping(bytes32 => bool) public usedSignatures;

  modifier onlyTokenOwner() {
    if (vault.ownerOf(tokenId()) != _msgSender()) revert NotTheTokenOwner();
    _;
  }

  // @dev see {IInheritanceManager.sol-init}
  // this must be execute immediately after the deployment
  function init(address registry_, address guardian_, address signatureValidator_) external virtual override {
    _addRole(keccak256("PROTECTOR"));
    _addRole(keccak256("SAFE_RECIPIENT"));
    if (msg.sender != tokenAddress()) revert Forbidden();
    guardian = Guardian(guardian_);
    signatureValidator = SignatureValidator(signatureValidator_);
    vault = ProtectedNFT(msg.sender);
    registry = IERC6551Registry(registry_);
  }

  function _authorizeUpgrade(address implementation) internal virtual override onlyTokenOwner {
    if (!guardian.isTrustedImplementation(keccak256("Manager"), implementation)) revert InvalidImplementation();
  }

  function plug(string memory name, address implementation) external virtual override onlyTokenOwner {
    bytes32 salt = keccak256(abi.encodePacked(name));
    if (address(plugins[salt]) != address(0)) revert PluginAlreadyPlugged();
    if (!guardian.isTrustedImplementation(salt, implementation)) revert InvalidImplementation();
    // the manager pretends to be an NFT to use the ERC-6551 registry
    registry.createAccount(implementation, salt, block.chainid, address(this), tokenId());
    address pluginAddress = registry.account(implementation, salt, block.chainid, address(this), tokenId());
    plugins[salt] = IPlugin(pluginAddress);
    plugins[salt].init(address(guardian), address(signatureValidator));
    bytes32[] memory roles = plugins[salt].pluginRoles();
    for (uint256 i = 0; i < roles.length; i++) {
      _addRole(roles[i]);
      pluginByRole[roles[i]] = salt;
    }
    emit PluginPlugged(name, pluginAddress);
  }

  // simulate ERC-721 to allow plugins to be deployed via ERC-6551 Registry
  function ownerOf(uint256) external view virtual override returns (address) {
    return owner();
  }

  // @dev Counts the protectors.
  function countActiveProtectors() public view virtual override returns (uint256) {
    return actorCount(PROTECTOR);
  }

  // @dev Find a specific protector
  function findProtectorIndex(address protector_) public view virtual override returns (uint256) {
    return actorIndex(protector_, PROTECTOR);
  }

  // @dev Returns true if the address is a protector.
  // @param protector_ The protector address.
  function isAProtector(address protector_) public view virtual override returns (bool) {
    return _isActiveActor(protector_, PROTECTOR);
  }

  // @dev Returns the list of protectors.
  function listProtectors() public view virtual override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  function hasProtectors() public view virtual override returns (bool) {
    return actorCount(PROTECTOR) > 0;
  }

  // @dev see {IInheritanceManager.sol-setProtector}
  function setProtector(
    address protector_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor("PROTECTOR", protector_, PROTECTOR, status, timestamp, validFor, signature, IS_MANAGER);
    emit ProtectorUpdated(_msgSender(), protector_, status);
    if (status) {
      if (countActiveProtectors() == 1) {
        vault.emitLockedEvent(tokenId(), true);
      }
    } else {
      if (countActiveProtectors() == 0) {
        vault.emitLockedEvent(tokenId(), false);
      }
    }
  }

  // @dev see {IInheritanceManager.sol-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  // safe recipients
  // @dev see {IInheritanceManager.sol-setSafeRecipient}
  // We do not set a batch function because it can be dangerous
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor("SAFE_RECIPIENT", recipient, SAFE_RECIPIENT, status, timestamp, validFor, signature, IS_NOT_MANAGER);
    emit SafeRecipientUpdated(_msgSender(), recipient, status);
  }

  // @dev see {IInheritanceManager.sol-isSafeRecipient}
  function isSafeRecipient(address recipient) public view virtual override returns (bool) {
    return actorIndex(recipient, SAFE_RECIPIENT) != MAX_ACTORS;
  }

  // @dev see {IInheritanceManager.sol-getSafeRecipients}
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return getActors(SAFE_RECIPIENT);
  }

  // internal functions

  // @dev Validates the request.
  // @param scope The scope of the request.
  // @param actor The actor of the request.
  // @param status The status of the actor
  // @param timestamp The timestamp of the request.
  // @param validFor The validity of the request.
  // @param signature The signature of the request.
  function _validateRequest(
    bytes32 scope,
    address actor,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) internal virtual {
    if (timestamp == 0) {
      if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (timestamp == 0) revert TimestampZero();
      if (timestamp > block.timestamp || timestamp < block.timestamp - validFor) revert TimestampInvalidOrExpired();
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      address signer = signatureValidator.recoverSigner(
        scope,
        owner(),
        actor,
        tokenId(),
        status,
        timestamp,
        validFor,
        signature
      );
      if (!isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
      usedSignatures[keccak256(signature)] = true;
    }
  }

  // @dev Adds an actor, validating the data.
  // @param roleString The scope of the request, i.e., the type of actor.
  // @param role_ The role of the actor.
  // @param actor The actor address.
  // @param status The status of the request.
  // @param timestamp The timestamp of the request.
  // @param validFor The validity of the request.
  // @param signature The signature of the request.
  function _setSignedActor(
    string memory roleString,
    address actor,
    bytes32 role_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    bool actorIsProtector
  ) internal virtual {
    bytes32 scope = keccak256(abi.encodePacked(roleString));
    if (actor == address(0)) revert ZeroAddress();
    if (actor == _msgSender()) revert CannotBeYourself();
    _validateRequest(scope, actor, status, timestamp, validFor, signature);
    if (!status) {
      if (timestamp != 0 && actorIsProtector && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && actorIsProtector && isAProtector(actor)) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  // This can be only called by plugins saving its own actors
  function setSignedActor(
    string memory roleString,
    address actor,
    bytes32 role_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override {
    bytes32 scope = keccak256(abi.encodePacked(roleString));
    if (roleIndex[scope] == 0) revert RoleNotFound();
    if (address(plugins[pluginByRole[scope]]) != _msgSender()) revert Forbidden();
    _setSignedActor(roleString, actor, role_, status, timestamp, validFor, signature, false);
  }

  // @dev See {IProtected721-managedTransfer}.
  function managedTransfer(uint256 tokenId, address to) external virtual override {
    if (address(plugins[keccak256("InheritanceManager")]) != _msgSender()) revert NotTheInheritanceManager();
    vault.managedTransfer(tokenId, to);
    _resetActors();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
