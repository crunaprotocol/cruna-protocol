// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Actor} from "./Actor.sol";
import {IManager} from "./IManager.sol";
import {IPlugin} from "../plugins/IPlugin.sol";
import {ManagerBase} from "./ManagerBase.sol";

//import {console} from "hardhat/console.sol";

interface IProxy {
  function isProxy() external pure returns (bool);
}

contract Manager is IManager, Actor, ManagerBase {
  using ECDSA for bytes32;
  using Strings for uint256;
  using Address for address;

  error Forbidden();
  error ProtectorNotFound();
  error ProtectorAlreadySetByYou();
  error NotPermittedWhenProtectorsAreActive();
  error TimestampInvalidOrExpired();
  error WrongDataOrNotSignedByProtector();
  error SignatureAlreadyUsed();
  error CannotBeYourself();
  error NotAuthorized();
  error PluginAlreadyPlugged();
  error NotAProxy();
  error ContractsCannotBeProtectors();
  error PluginNotFound();
  error DisabledPlugin();
  error InconsistentPolicy();

  bytes32 public constant PROTECTOR = keccak256("PROTECTOR");
  bytes32 public constant SAFE_RECIPIENT = keccak256("SAFE_RECIPIENT");

  mapping(bytes32 => bool) public usedSignatures;

  mapping(bytes32 => IPlugin) public plugins;
  mapping(bytes32 => bytes32) public pluginNamesByRole;
  bytes32[] public pluginRoles;

  mapping(bytes32 => bool) public disabledPlugins;

  function nameHash() public virtual override returns (bytes32) {
    return keccak256("Manager");
  }

  function plug(string memory name, address pluginProxy) external virtual override onlyTokenOwner {
    try IProxy(pluginProxy).isProxy() returns (bool) {} catch {
      revert NotAProxy();
    }
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (address(plugins[_nameHash]) != address(0)) revert PluginAlreadyPlugged();
    if (!guardian().isTrustedImplementation(_nameHash, pluginProxy)) revert InvalidImplementation();
    // the manager pretends to be an NFT to use the ERC-6551 registry
    registry().createAccount(pluginProxy, _nameHash, block.chainid, address(this), tokenId());
    address pluginAddress = registry().account(pluginProxy, _nameHash, block.chainid, address(this), tokenId());
    plugins[_nameHash] = IPlugin(pluginAddress);
    plugins[_nameHash].init();
    bytes32[] memory roles = plugins[_nameHash].pluginRoles();
    for (uint256 i = 0; i < roles.length; i++) {
      pluginNamesByRole[roles[i]] = _nameHash;
      pluginRoles.push(roles[i]);
    }
    emit PluginStatusChange(name, pluginAddress, true);
  }

  // Plugin cannot be unplugged since they have been deployed via ERC-6551 Registry
  // so, we mark them as disabled
  function disablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner {
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (address(plugins[_nameHash]) == address(0)) revert PluginNotFound();
    disabledPlugins[_nameHash] = true;
    if (resetPlugin) {
      _resetPlugin(_nameHash);
    }
    emit PluginStatusChange(name, address(plugins[_nameHash]), false);
  }

  function reEnablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner {
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (disabledPlugins[_nameHash] == false) revert PluginNotFound();
    delete disabledPlugins[_nameHash];
    if (resetPlugin) {
      _resetPlugin(_nameHash);
    }
    emit PluginStatusChange(name, address(plugins[_nameHash]), true);
  }

  function _resetPlugin(bytes32 _nameHash) internal virtual {
    for (uint256 k = 0; k < pluginRoles.length; k++) {
      if (pluginNamesByRole[pluginRoles[k]] == _nameHash) {
        _cleanActors(pluginRoles[k]);
      }
    }
    plugins[_nameHash].reset();
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

  // @dev see {IManager-setProtector}
  function setProtector(
    address protector_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    if (protector_.isContract()) revert ContractsCannotBeProtectors();
    _setSignedActor("PROTECTOR", protector_, PROTECTOR, status, timestamp, validFor, signature, true, _msgSender());
    emit ProtectorUpdated(_msgSender(), protector_, status);
    if (status) {
      if (countActiveProtectors() == 1) {
        vault().emitLockedEvent(tokenId(), true);
      }
    } else {
      if (countActiveProtectors() == 0) {
        vault().emitLockedEvent(tokenId(), false);
      }
    }
  }

  // @dev see {IManager-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  // safe recipients
  // @dev see {IManager-setSafeRecipient}
  // We do not set a batch function because it can be dangerous
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor("SAFE_RECIPIENT", recipient, SAFE_RECIPIENT, status, timestamp, validFor, signature, false, _msgSender());
    emit SafeRecipientUpdated(_msgSender(), recipient, status);
  }

  // @dev see {IManager-isSafeRecipient}
  function isSafeRecipient(address recipient) public view virtual override returns (bool) {
    return actorIndex(recipient, SAFE_RECIPIENT) != MAX_ACTORS;
  }

  // @dev see {IManager-getSafeRecipients}
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
      if (timestamp > block.timestamp || timestamp < block.timestamp - validFor) revert TimestampInvalidOrExpired();
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      address signer = validator().recoverSetActorSigner(
        scope,
        owner(),
        actor,
        tokenId(),
        status ? 1 : 0,
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
    bool actorIsProtector,
    address sender
  ) internal virtual {
    bytes32 scope = keccak256(abi.encodePacked(roleString));
    if (actor == address(0)) revert ZeroAddress();
    if (actor == sender) revert CannotBeYourself();
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
    bytes calldata signature,
    address sender
  ) external virtual override {
    bytes32 scope = keccak256(abi.encodePacked(roleString));
    if (address(plugins[pluginNamesByRole[scope]]) != _msgSender()) revert Forbidden();
    if (disabledPlugins[pluginNamesByRole[scope]]) revert DisabledPlugin();
    _setSignedActor(roleString, actor, role_, status, timestamp, validFor, signature, false, sender);
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by the InheritancePlugin
  function managedTransfer(uint256 tokenId, address to) external virtual override {
    // Since only a bunch of plugins can manage transfers, ideally only one,
    // there is no risk of going out of gas
    for (uint256 i = 0; i < pluginRoles.length; i++) {
      if (address(plugins[pluginNamesByRole[pluginRoles[i]]]) == _msgSender()) {
        if (!plugins[pluginNamesByRole[pluginRoles[i]]].requiresToManageTransfer()) {
          // The plugin declares itself as not requiring the ability to manage transfers, but in reality it is trying to do so
          revert InconsistentPolicy();
        }
        if (disabledPlugins[pluginNamesByRole[pluginRoles[i]]]) revert DisabledPlugin();
        vault().managedTransfer(tokenId, to);
        _resetActors();
        return;
      }
    }
    revert NotAuthorized();
  }

  function _resetActors() internal virtual {
    _cleanActors(PROTECTOR);
    _cleanActors(SAFE_RECIPIENT);
    for (uint256 k = 0; k < pluginRoles.length; k++) {
      _cleanActors(pluginRoles[k]);
    }
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
