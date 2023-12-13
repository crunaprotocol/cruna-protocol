// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {Actor} from "./Actor.sol";
import {IManager} from "./IManager.sol";
import {IPlugin} from "../plugins/IPlugin.sol";
import {ManagerBase} from "./ManagerBase.sol";

//import {console} from "hardhat/console.sol";

interface IProxy {
  function isProxy() external pure returns (bool);
}

contract Manager is IManager, Actor, ManagerBase, ReentrancyGuard {
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
  error NotTheAuthorizedPlugin();
  error PluginAlreadyPlugged();
  error NotAProxy();
  error ContractsCannotBeProtectors();
  error PluginNotFound();
  error DisabledPlugin();
  error InconsistentPolicy();
  error PluginNotFoundOrDisabled();
  error RoleNotAuthorizedFor(bytes32 role, bytes32 pluginNameHash);

  bytes4 public constant PROTECTOR = bytes4(keccak256("PROTECTOR"));
  bytes4 public constant SAFE_RECIPIENT = bytes4(keccak256("SAFE_RECIPIENT"));

  bytes32 public constant SALT = bytes32(uint256(69));

  mapping(bytes32 => bool) public usedSignatures;

  mapping(bytes32 => Plugin) public pluginsByName;
  bytes32[] public pluginNames;
  bytes32[] public registeredPluginRoles;

  function nameHash() public virtual override returns (bytes4) {
    return bytes4(keccak256("Manager"));
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
    _setSignedActor(nameHash(), "PROTECTOR", protector_, status, timestamp, validFor, signature, true, _msgSender());
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
    _setSignedActor(nameHash(), "SAFE_RECIPIENT", recipient, status, timestamp, validFor, signature, false, _msgSender());
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
    bytes32 _nameHash,
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
    bytes32 _nameHash,
    string memory roleString,
    address actor,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    bool actorIsProtector,
    address sender
  ) internal virtual {
    bytes32 role_ = keccak256(abi.encodePacked(roleString));
    if (actor == address(0)) revert ZeroAddress();
    if (actor == sender) revert CannotBeYourself();
    _validateRequest(role_, actor, status, timestamp, validFor, signature);
    if (!status) {
      if (timestamp != 0 && actorIsProtector && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && actorIsProtector && isAProtector(actor)) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  /**
   *
   * PLUGINS
   *
   */

  function plug(string memory name, address pluginProxy) external virtual override onlyTokenOwner nonReentrant {
    try IProxy(pluginProxy).isProxy() returns (bool) {} catch {
      revert NotAProxy();
    }
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (pluginsByName[_nameHash] != address(0)) revert PluginAlreadyPlugged();
    pluginsByName[_nameHash] = Plugin(pluginProxy, true);
    pluginNames.push(_nameHash);
    if (!guardian().isTrustedImplementation(_nameHash, pluginProxy)) revert InvalidImplementation();
    registry().createAccount(pluginProxy, SALT, block.chainid, address(this), tokenId());
    IPlugin _plugin = plugin(_nameHash);
    if (_plugin.nameHash() != _nameHash) revert InvalidImplementation();
    emit PluginStatusChange(name, address(_plugin), true);
    _plugin.init();
  }

  function plugin(bytes32 _nameHash) public view virtual returns (IPlugin) {
    return IPlugin(registry().account(pluginsByName[_nameHash].proxyAddress, SALT, block.chainid, address(this), tokenId()));
  }

  function pluginRoles(bytes32 _nameHash) public view virtual returns (bytes32[] memory) {
    return plugin(_nameHash).pluginRoles();
  }

  function isPluginSRole(bytes32 _nameHash, bytes32 role) public view virtual returns (bool) {
    return plugin(_nameHash).isPluginSRole(role);
  }

  // Plugin cannot be unplugged since they have been deployed via ERC-6551 Registry
  // so, we mark them as disabled
  function disablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner nonReentrant {
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (pluginsByName[_nameHash].proxyAddress == address(0)) revert PluginNotFound();
    pluginsByName[_nameHash].active = false;
    if (resetPlugin) {
      _resetPlugin(_nameHash);
    }
    emit PluginStatusChange(name, address(pluginNames[_nameHash]), false);
  }

  function reEnablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner nonReentrant {
    bytes32 _nameHash = keccak256(abi.encodePacked(name));
    if (pluginsByName[_nameHash].proxyAddress == address(0) || pluginsByName[_nameHash].active) revert PluginNotFound();
    pluginsByName[_nameHash].active = true;
    if (resetPlugin) {
      _resetPlugin(_nameHash);
    }
    emit PluginStatusChange(name, address(pluginNames[_nameHash]), true);
  }

  function _resetPlugin(bytes32 _nameHash) internal virtual {
    IPlugin _plugin = plugin(_nameHash);
    bytes32 memory roles = _plugin.pluginRoles();
    for (uint256 i = 0; i < roles.length; i++) {
      _deleteActors(roles[i]);
    }
    _plugin.reset();
  }

  function _authorizedPlugin(bytes32 pluginNameHash) internal view virtual returns (IPlugin) {
    if (!pluginsByName[pluginNameHash].active) revert PluginNotFoundOrDisabled();
    IPlugin _plugin = plugin(pluginNameHash);
    if (address(_plugin) != _msgSender()) revert NotTheAuthorizedPlugin();
    return _plugin;
  }

  // This can be only called by plugins saving its own actors
  function setSignedActor(
    bytes32 pluginNameHash,
    string memory roleString,
    address actor,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    address sender
  ) external virtual override {
    if (role_ == PROTECTOR || role_ == SAFE_RECIPIENT) revert Forbidden();
    IPlugin _plugin = _authorizedPlugin(pluginNameHash);
    if (!_plugin.isPluginRole(role_)) revert RoleNotAuthorizedFor(role_, pluginNameHash);
    _setSignedActor(pluginNameHash, roleString, actor, status, timestamp, validFor, signature, false, sender);
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by the InheritancePlugin
  function managedTransfer(bytes32 pluginNameHash, uint256 tokenId, address to) external virtual override nonReentrant {
    IPlugin _plugin = _authorizedPlugin(pluginNameHash);
    if (!_plugin.requiresToManageTransfer()) {
      // The plugin declares itself as not requiring the ability to manage transfers, but in reality it is trying to do so
      revert InconsistentPolicy();
    }
    vault().managedTransfer(pluginNamesByRole[pluginRoles[i]], tokenId, to);
    _deleteActors(PROTECTOR);
    _deleteActors(SAFE_RECIPIENT);
    for (uint256 i = 0; i < pluginNames.length; i++) {
      _plugin = plugin(pluginNames[i]);
      _plugin.reset();
    }
  }

  function _resetActors(bytes32 pluginNameHash, bytes32 role_) external virtual {
    if (role_ == PROTECTOR || role_ == SAFE_RECIPIENT) revert Forbidden();
    IPlugin _plugin = _authorizedPlugin(pluginNameHash);
    if (!_plugin.isPluginRole(role_)) revert RoleNotAuthorizedFor(role_, pluginNameHash);
    _deleteActors(role_);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
