// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {Actor} from "./Actor.sol";
import {IManager} from "./IManager.sol";
import {IPlugin} from "../plugins/IPlugin.sol";
import {ManagerBase} from "./ManagerBase.sol";
import {SignatureValidator} from "../utils/SignatureValidator.sol";

//import {console} from "hardhat/console.sol";

interface IProxy {
  function isProxy() external pure returns (bool);
}

interface IPluginExt is IPlugin {
  function nameId() external returns (bytes4);
}

contract Manager is IManager, Actor, ManagerBase, ReentrancyGuard, SignatureValidator {
  using ECDSA for bytes32;
  using Strings for uint256;

  error ProtectorNotFound();
  error ProtectorAlreadySetByYou();
  error NotPermittedWhenProtectorsAreActive();
  error WrongDataOrNotSignedByProtector();
  error CannotBeYourself();
  error NotTheAuthorizedPlugin();
  error SignatureAlreadyUsed();
  error NotAProxy();
  error PluginAlreadyPlugged();
  error PluginNotFound();
  error PluginNotFoundOrDisabled();
  error PluginNotDisabled();
  error PluginAlreadyDisabled();
  error PluginNotAuthorizedToManageTransfer();
  error PluginAlreadyAuthorized();
  error PluginAlreadyUnauthorized();
  error NotATransferPlugin();
  error InvalidImplementation();

  mapping(bytes32 => bool) public usedSignatures;
  bytes4 public constant PROTECTOR = bytes4(keccak256("PROTECTOR"));
  bytes4 public constant SAFE_RECIPIENT = bytes4(keccak256("SAFE_RECIPIENT"));

  bytes32 public constant SALT = bytes32(uint256(69));

  mapping(bytes4 => Plugin) public pluginsById;
  PluginStatus[] public allPlugins;

  function nameId() public virtual override returns (bytes4) {
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
    _setSignedActor(nameId(), PROTECTOR, protector_, status, timestamp, validFor, signature, true, _msgSender());
    emit ProtectorUpdated(_msgSender(), protector_, status);
    if (status) {
      if (countActiveProtectors() == 1) {
        _emitLockedEvent(true);
      }
    } else {
      if (countActiveProtectors() == 0) {
        _emitLockedEvent(false);
      }
    }
  }

  function _emitLockedEvent(bool locked_) internal virtual {
    // Avoid to revert if the emission of the event fails.
    // It should never happen, but if it happens, we are
    // notified by the LockFailed event, instead of reverting
    // the entire transaction.
    bytes memory data = abi.encodeWithSignature("emitLockedEvent(uint256,bool)", tokenId(), locked_);
    address vaultAddress = address(vault());
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = vaultAddress.call(data);
    if (!success) {
      // this way we can ask the user to execute an explicit lock
      emit LockFailed(tokenId(), locked_);
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
    _setSignedActor(nameId(), SAFE_RECIPIENT, recipient, status, timestamp, validFor, signature, false, _msgSender());
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

  // @dev Validates the request.
  // @param scope The scope of the request.
  // @param actor The actor of the request.
  // @param status The status of the actor
  // @param timestamp The timestamp of the request.
  // @param validFor The validity of the request.
  // @param signature The signature of the request.
  function _validateAndCheckSignature(
    bytes4 _nameId,
    bytes4 _funcHash,
    address target,
    bool status,
    uint256 timeValidation,
    bytes calldata signature,
    bool settingProtector
  ) internal virtual {
    if (!settingProtector && timeValidation < 1e6) {
      if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    } else {
      bytes32 scope = combineBytes4(_nameId, _funcHash);
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      usedSignatures[keccak256(signature)] = true;
      address signer = recoverSigner(
        scope,
        owner(),
        target,
        tokenAddress(),
        tokenId(),
        status ? 1 : 0,
        0,
        0,
        timeValidation,
        signature
      );
      if (settingProtector && countActiveProtectors() == 0) {
        if (signer != target) revert WrongDataOrNotSignedByProtector();
      } else if (!isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
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
    bytes4 _nameId,
    bytes4 role_,
    address actor,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature,
    bool actorIsProtector,
    address sender
  ) internal virtual {
    if (actor == address(0)) revert ZeroAddress();
    if (actor == sender) revert CannotBeYourself();
    _validateAndCheckSignature(_nameId, role_, actor, status, timestamp * 1e6 + validFor, signature, actorIsProtector);
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

  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer
  ) external virtual override onlyTokenOwner nonReentrant {
    try IProxy(pluginProxy).isProxy() returns (bool) {} catch {
      revert NotAProxy();
    }
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId].proxyAddress != address(0)) revert PluginAlreadyPlugged();
    uint256 requires = guardian().trustedImplementation(_nameId, pluginProxy);
    if (requires == 0) revert UntrustedImplementation();
    if (requires > version()) revert PluginRequiresUpdatedManager(requires);
    address _pluginAddress = registry().createBoundContract(pluginProxy, SALT, block.chainid, address(this), tokenId());
    IPluginExt _plugin = IPluginExt(_pluginAddress);
    if (_plugin.nameId() != _nameId) revert InvalidImplementation();
    allPlugins.push(PluginStatus(name, true));
    pluginsById[_nameId] = Plugin(pluginProxy, canManageTransfer, true);
    _plugin.init();
    emit PluginStatusChange(name, address(_plugin), true);
  }

  function authorizePluginToTransfer(string memory name, bool authorized) external virtual onlyTokenOwner {
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId].proxyAddress == address(0)) revert PluginNotFound();
    if (authorized) {
      if (pluginsById[_nameId].canManageTransfer) revert PluginAlreadyAuthorized();
    } else if (!pluginsById[_nameId].canManageTransfer) revert PluginAlreadyUnauthorized();
    IPluginExt _plugin = plugin(_nameId);
    if (!_plugin.requiresToManageTransfer()) revert NotATransferPlugin();
    pluginsById[_nameId].canManageTransfer = authorized;
  }

  function pluginAddress(bytes4 _nameId) public view virtual returns (address) {
    return registry().boundContract(pluginsById[_nameId].proxyAddress, SALT, block.chainid, address(this), tokenId());
  }

  function plugin(bytes4 _nameId) public view virtual returns (IPluginExt) {
    return IPluginExt(pluginAddress(_nameId));
  }

  function countPlugins() public view virtual returns (uint256, uint256) {
    uint256 active;
    uint256 disabled;
    for (uint256 i = 0; i < allPlugins.length; i++) {
      if (allPlugins[i].active) active++;
      else disabled++;
    }
    return (active, disabled);
  }

  function plugged(string memory name) public view virtual returns (bool) {
    bytes4 _nameId = _stringToBytes4(name);
    return pluginsById[_nameId].proxyAddress != address(0);
  }

  function pluginIndex(string memory name) public view virtual returns (bool, uint256) {
    for (uint256 i = 0; i < allPlugins.length; i++) {
      if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(allPlugins[i].name))) {
        return (true, i);
      }
    }
    return (false, 0);
  }

  function isPluginActive(string memory name) public view virtual returns (bool) {
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId].proxyAddress == address(0)) revert PluginNotFound();
    return pluginsById[_nameId].active;
  }

  function listPlugins(bool active) external view virtual returns (string[] memory) {
    (uint256 actives, uint256 disabled) = countPlugins();
    string[] memory _plugins = new string[](active ? actives : disabled);
    for (uint256 i = 0; i < allPlugins.length; i++) {
      if (allPlugins[i].active == active) {
        _plugins[i] = allPlugins[i].name;
      }
    }
    return _plugins;
  }

  function disablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner nonReentrant {
    (bool plugged_, uint256 i) = pluginIndex(name);
    if (!plugged_) revert PluginNotFound();
    if (!allPlugins[i].active) revert PluginAlreadyDisabled();
    allPlugins[i].active = false;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId].active = false;
    if (resetPlugin) {
      _resetPlugin(_nameId);
    }
    emit PluginStatusChange(name, pluginAddress(_nameId), false);
  }

  function reEnablePlugin(string memory name, bool resetPlugin) external virtual override onlyTokenOwner nonReentrant {
    (bool plugged_, uint256 i) = pluginIndex(name);
    if (!plugged_) revert PluginNotFound();
    if (allPlugins[i].active) revert PluginNotDisabled();
    allPlugins[i].active = true;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId].active = true;
    if (resetPlugin) {
      _resetPlugin(_nameId);
    }
    emit PluginStatusChange(name, pluginAddress(_nameId), true);
  }

  function _resetPlugin(bytes4 _nameId) internal virtual {
    IPluginExt _plugin = plugin(_nameId);
    _plugin.reset();
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by the InheritancePlugin
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual override nonReentrant {
    if (pluginsById[pluginNameId].proxyAddress == address(0) || !pluginsById[pluginNameId].active)
      revert PluginNotFoundOrDisabled();
    if (!pluginsById[pluginNameId].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
    if (pluginAddress(pluginNameId) != _msgSender()) revert NotTheAuthorizedPlugin();
    _resetActorsAndDisablePlugins();
    // In theory, the vault may revert, blocking the entire process
    // We allow it, assuming that the vault implementation has the
    // right to set up more advanced rules, before allowing the transfer,
    // despite the plugin has the ability to do so.
    vault().managedTransfer(pluginNameId, tokenId, to);
  }

  function _resetActorsAndDisablePlugins() internal virtual {
    _deleteActors(PROTECTOR);
    _deleteActors(SAFE_RECIPIENT);
    // disable all plugins
    if (allPlugins.length > 0) {
      for (uint256 i = 0; i < allPlugins.length; i++) {
        allPlugins[i].active = false;
        bytes4 _nameId = _stringToBytes4(allPlugins[i].name);
        pluginsById[_nameId].active = false;
        _resetPlugin(_nameId);
      }
      emit AllPluginsDisabled();
    }
  }

  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timeValidation,
    bytes calldata signature
  ) external onlyTokenOwner {
    _validateAndCheckSignature(nameId(), _stringToBytes4("protectedTransfer"), to, false, timeValidation, signature, false);
    _resetActorsAndDisablePlugins();
    vault().managedTransfer(nameId(), tokenId, to);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
