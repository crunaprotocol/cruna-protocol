// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {Actor} from "./Actor.sol";
import {ICrunaPlugin} from "../plugins/ICrunaPlugin.sol";
import {CrunaManagerBase} from "./CrunaManagerBase.sol";

//import {console} from "hardhat/console.sol";

contract CrunaManager is Actor, CrunaManagerBase, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;

  error ProtectorNotFound();
  error ProtectorAlreadySetByYou();
  error NotPermittedWhenProtectorsAreActive();
  error WrongDataOrNotSignedByProtector();
  error CannotBeYourself();
  error NotTheAuthorizedPlugin();
  error SignatureAlreadyUsed();
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
  error InvalidTimeLock();
  error InvalidValidity();

  bytes4 public constant PROTECTOR = bytes4(keccak256("PROTECTOR"));
  bytes4 public constant SAFE_RECIPIENT = bytes4(keccak256("SAFE_RECIPIENT"));

  mapping(bytes4 => CrunaPlugin) public pluginsById;
  PluginStatus[] public allPlugins;
  mapping(bytes4 => uint256) public timeLocks;

  // @dev Counts the protectors.
  function countActiveProtectors() public view virtual override returns (uint256) {
    return _actors[PROTECTOR].length;
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

  // from SignatureValidator
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual override returns (bool) {
    if (_actors[PROTECTOR].length == 0) {
      // if there are no protectors, the signer can pre-approve its own candidate
      return selector == this.setProtector.selector && actor == signer;
    } else return _isActiveActor(signer, PROTECTOR);
  }

  // @dev Returns the list of protectors.
  function listProtectors() public view virtual override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  function hasProtectors() public view virtual override returns (bool) {
    return actorCount(PROTECTOR) > 0;
  }

  function isTransferable(address to) external view override returns (bool) {
    return !hasProtectors() || isSafeRecipient(to);
  }

  function locked() external view override returns (bool) {
    return hasProtectors();
  }

  // @dev see {ICrunaManager.sol-setProtector}
  function setProtector(
    address protector_,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor(
      this.setProtector.selector,
      PROTECTOR,
      protector_,
      status,
      timestamp,
      validFor,
      signature,
      true,
      _msgSender()
    );
    emit ProtectorChange(protector_, status);
    _emitLockeEvent(status);
  }

  // @dev see {ICrunaManager.sol-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return getActors(PROTECTOR);
  }

  // safe recipients
  // @dev see {ICrunaManager.sol-setSafeRecipient}
  // We do not set a batch function because it can be dangerous
  function setSafeRecipient(
    address recipient,
    bool status,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    _setSignedActor(
      this.setSafeRecipient.selector,
      SAFE_RECIPIENT,
      recipient,
      status,
      timestamp,
      validFor,
      signature,
      false,
      _msgSender()
    );
    emit SafeRecipientChange(recipient, status);
  }

  // @dev see {ICrunaManager.sol-isSafeRecipient}
  function isSafeRecipient(address recipient) public view virtual override returns (bool) {
    return actorIndex(recipient, SAFE_RECIPIENT) != MAX_ACTORS;
  }

  // @dev see {ICrunaManager.sol-getSafeRecipients}
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return getActors(SAFE_RECIPIENT);
  }

  // @dev Validates the request.
  // @param _functionSelector The function selector of the request.
  // @param target The target of the request.
  // @param status The status of the actor
  // @param timeValidation The timestamp of the request:
  //    timestamp * 1e7 + validFor
  // @param signature The signature of the request.
  // @param settingProtector True if the request is setting a protector.
  function _validateAndCheckSignature(
    bytes4 _functionSelector,
    address target,
    bool status,
    uint256 extra2,
    uint256 timeValidation,
    bytes calldata signature,
    bool settingProtector
  ) internal virtual {
    if (!settingProtector && timeValidation < 1e7) {
      if (countActiveProtectors() > 0) revert NotPermittedWhenProtectorsAreActive();
    } else {
      if (usedSignatures[keccak256(signature)]) revert SignatureAlreadyUsed();
      usedSignatures[keccak256(signature)] = true;
      (address signer, bytes32 hash) = recoverSigner(
        _functionSelector,
        owner(),
        target,
        tokenAddress(),
        tokenId(),
        status ? 1 : 0,
        extra2,
        0,
        timeValidation,
        signature
      );
      if (settingProtector && countActiveProtectors() == 0) {
        if (signer != target) revert WrongDataOrNotSignedByProtector();
      } else if (!isAProtector(signer)) revert WrongDataOrNotSignedByProtector();
      delete preApprovals[hash];
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
    bytes4 _functionSelector,
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
    if (validFor > 9999999) revert InvalidValidity();
    _validateAndCheckSignature(_functionSelector, actor, status, 0, timestamp * 1e7 + validFor, signature, actorIsProtector);
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

  // TODO require a protector signature if protectors are active
  //   actor = pluginProxy
  //   extra = canManageTransfer ? 1 : 0;
  //   extra2 = uint256(bytes32(bytes(name)));
  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    if (validFor > 9999999) revert InvalidValidity();
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId].proxyAddress != address(0)) revert PluginAlreadyPlugged();
    uint256 requires = guardian().trustedImplementation(_nameId, pluginProxy);
    if (requires == 0) revert UntrustedImplementation();
    if (requires > version()) revert PluginRequiresUpdatedManager(requires);
    _validateAndCheckSignature(
      this.plug.selector,
      pluginProxy,
      canManageTransfer,
      0,
      timestamp * 1e7 + validFor,
      signature,
      false
    );
    address _pluginAddress = registry().createTokenLinkedContract(pluginProxy, 0x00, block.chainid, address(this), tokenId());
    ICrunaPlugin _plugin = ICrunaPlugin(_pluginAddress);
    if (_plugin.nameId() != _nameId) revert InvalidImplementation();
    allPlugins.push(PluginStatus(name, true));
    pluginsById[_nameId] = CrunaPlugin(pluginProxy, canManageTransfer, _plugin.requiresResetOnTransfer(), true);
    _plugin.init();
    _emitPluginStatusChange(name, address(_plugin), true);
  }

  function _emitPluginStatusChange(string memory name, address pluginAddress_, bool status) internal virtual {
    // Avoid to revert if the emission of the event fails.
    // It should never happen, but if it happens, we are
    // notified by the EmitEventFailed event, instead of reverting
    // the entire transaction.
    emit PluginStatusChange(name, pluginAddress_, status);
  }

  // @dev Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
  // the NFT. If the plugins must be blocked for more time, disable it
  function authorizePluginToTransfer(
    string memory name,
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    if (validFor > 9999999) revert InvalidValidity();
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId].proxyAddress == address(0)) revert PluginNotFound();
    ICrunaPlugin _plugin = plugin(_nameId);
    if (!_plugin.requiresToManageTransfer()) revert NotATransferPlugin();
    _validateAndCheckSignature(
      this.authorizePluginToTransfer.selector,
      pseudoAddress(name),
      authorized,
      timeLock,
      timestamp * 1e7 + validFor,
      signature,
      false
    );
    if (authorized) {
      if (timeLock > 0) revert InvalidTimeLock();
      if (pluginsById[_nameId].canManageTransfer) revert PluginAlreadyAuthorized();
      delete timeLocks[_nameId];
    } else {
      if (!pluginsById[_nameId].canManageTransfer) revert PluginAlreadyUnauthorized();
      if (timeLock == 0 || timeLock > 30 days) revert InvalidTimeLock();
      timeLocks[_nameId] = block.timestamp + timeLock;
    }
    pluginsById[_nameId].canManageTransfer = authorized;
    emit PluginAuthorizationChange(name, pluginAddress(_nameId), authorized, timeLock);
  }

  function _emitLockeEvent(bool status) internal virtual {
    uint256 protectorsCount = countActiveProtectors();
    if ((status && protectorsCount == 1) || (!status && protectorsCount == 0)) {
      // Avoid to revert if the emission of the event fails.
      // It should never happen, but if it happens, we are
      // notified by the EmitEventFailed event, instead of reverting
      // the entire transaction.
      bytes memory data = abi.encodeWithSignature("emitLockedEvent(uint256,bool)", tokenId(), status && protectorsCount == 1);
      address vaultAddress = address(vault());
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = vaultAddress.call(data);
      if (!success) {
        // we emit a local event to alert. Not ideal, but better than reverting
        emit EmitEventFailed(EventAction.PluginStatusChange);
      }
    }
  }

  function pluginAddress(bytes4 _nameId) public view virtual override returns (address) {
    return registry().tokenLinkedContract(pluginsById[_nameId].proxyAddress, 0x00, block.chainid, address(this), tokenId());
  }

  function plugin(bytes4 _nameId) public view virtual override returns (ICrunaPlugin) {
    return ICrunaPlugin(pluginAddress(_nameId));
  }

  function countPlugins() public view virtual override returns (uint256, uint256) {
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

  function pseudoAddress(string memory name) public view virtual returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(name)))));
  }

  function disablePlugin(
    string memory name,
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    if (validFor > 9999999) revert InvalidValidity();
    (bool plugged_, uint256 i) = pluginIndex(name);
    if (!plugged_) revert PluginNotFound();
    if (!allPlugins[i].active) revert PluginAlreadyDisabled();
    _validateAndCheckSignature(
      this.disablePlugin.selector,
      pseudoAddress(name),
      resetPlugin,
      0,
      timestamp * 1e7 + validFor,
      signature,
      false
    );
    allPlugins[i].active = false;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId].active = false;
    if (resetPlugin && pluginsById[_nameId].canBeReset) {
      _resetPlugin(_nameId);
    }
    _emitPluginStatusChange(name, pluginAddress(_nameId), false);
  }

  function reEnablePlugin(
    string memory name,
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    if (validFor > 9999999) revert InvalidValidity();
    (bool plugged_, uint256 i) = pluginIndex(name);
    if (!plugged_) revert PluginNotFound();
    if (allPlugins[i].active) revert PluginNotDisabled();
    _validateAndCheckSignature(
      this.reEnablePlugin.selector,
      pseudoAddress(name),
      resetPlugin,
      0,
      timestamp * 1e7 + validFor,
      signature,
      false
    );
    allPlugins[i].active = true;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId].active = true;
    if (resetPlugin && pluginsById[_nameId].canBeReset) {
      _resetPlugin(_nameId);
    }
    _emitPluginStatusChange(name, pluginAddress(_nameId), true);
  }

  function _resetPlugin(bytes4 _nameId) internal virtual {
    ICrunaPlugin _plugin = plugin(_nameId);
    _plugin.reset();
  }

  function _removeLockIfExpired(bytes4 _nameId) internal virtual {
    if (timeLocks[_nameId] < block.timestamp) {
      delete timeLocks[_nameId];
      pluginsById[_nameId].canManageTransfer = true;
    }
  }

  function updateEmitterForPlugin(bytes4 pluginNameId, address newEmitter) external virtual override {
    if (pluginsById[pluginNameId].proxyAddress == address(0)) revert PluginNotFound();
    pluginsById[pluginNameId].proxyAddress = newEmitter;
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by authorized plugins
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual override nonReentrant {
    if (pluginsById[pluginNameId].proxyAddress == address(0) || !pluginsById[pluginNameId].active)
      revert PluginNotFoundOrDisabled();
    _removeLockIfExpired(pluginNameId);
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
        if (pluginsById[_nameId].canBeReset) _resetPlugin(_nameId);
      }
    }
    emit Reset();
  }

  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    if (validFor > 9999999) revert InvalidValidity();
    _validateAndCheckSignature(this.protectedTransfer.selector, to, false, 0, timestamp * 1e7 + validFor, signature, false);
    _resetActorsAndDisablePlugins();
    vault().managedTransfer(nameId(), tokenId, to);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
