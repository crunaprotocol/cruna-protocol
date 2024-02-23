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
  error ProtectorsAlreadySet();

  error CannotBeYourself();
  error NotTheAuthorizedPlugin();

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
  error InvalidAccountStatus();
  error UntrustedImplementationsCanMakeTransfersOnlyOnTestnet();
  error CannotImportFromYourself();
  error NotTheSameOwner();
  error NoProtectorsToImport();
  error SafeRecipientsAlreadySet();

  bytes4 public constant PROTECTOR = bytes4(keccak256("PROTECTOR"));
  bytes4 public constant SAFE_RECIPIENT = bytes4(keccak256("SAFE_RECIPIENT"));

  mapping(bytes4 => mapping(bytes4 => CrunaPlugin)) public pluginsById;
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

  function _isProtected() internal view virtual override returns (bool) {
    return actorCount(PROTECTOR) > 0;
  }

  function _isProtector(address protector_) internal view virtual override returns (bool) {
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

  function version() public pure virtual override returns (uint256) {
    // 1.0.1
    return 1e6 + 1;
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
      1e17,
      _msgSender()
    );
    emit ProtectorChange(protector_, status);
    _emitLockeEvent(status);
  }

  // only to set up many protectors at the same time as first protectors
  function setProtectors(address[] memory protectors_) external virtual override onlyTokenOwner {
    if (actorCount(PROTECTOR) > 0) revert ProtectorsAlreadySet();
    _setProtectors(protectors_);
  }

  function _setProtectors(address[] memory protectors_) internal virtual {
    for (uint256 i = 0; i < protectors_.length; i++) {
      if (protectors_[i] == address(0)) revert ZeroAddress();
      if (protectors_[i] == _msgSender()) revert CannotBeYourself();
      _addActor(protectors_[i], PROTECTOR);
      emit ProtectorChange(protectors_[i], true);
      if (i == 0) _emitLockeEvent(true);
    }
  }

  function importFrom(uint256 otherTokenId) external virtual override onlyTokenOwner {
    if (actorCount(PROTECTOR) > 0) revert ProtectorsAlreadySet();
    if (actorCount(SAFE_RECIPIENT) > 0) revert SafeRecipientsAlreadySet();
    if (otherTokenId == tokenId()) revert CannotImportFromYourself();
    if (vault().ownerOf(otherTokenId) != owner()) revert NotTheSameOwner();
    CrunaManager otherManager = CrunaManager(vault().managerOf(otherTokenId));
    if (otherManager.actorCount(PROTECTOR) == 0) revert NoProtectorsToImport();
    _setProtectors(otherManager.getProtectors());
    if (otherManager.actorCount(SAFE_RECIPIENT) > 0) {
      address[] memory otherSafeRecipients = otherManager.getSafeRecipients();
      for (uint256 i = 0; i < otherSafeRecipients.length; i++) {
        _addActor(otherSafeRecipients[i], SAFE_RECIPIENT);
        emit SafeRecipientChange(otherSafeRecipients[i], true);
      }
    }
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
      0,
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
    uint256 actorIsProtector,
    address sender
  ) internal virtual {
    if (actor == address(0)) revert ZeroAddress();
    if (actor == sender) revert CannotBeYourself();
    if (validFor > 9999999) revert InvalidValidity();
    // to avoid too-deep stack error
    validFor = timestamp * 1e7 + validFor + actorIsProtector;
    _preValidateAndCheckSignature(_functionSelector, actor, status ? 1 : 0, 0, 0, validFor, signature);
    if (!status) {
      if (timestamp != 0 && actorIsProtector > 0 && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && actorIsProtector > 0 && isAProtector(actor)) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  /**
   *
   * PLUGINS
   *
   */

  //   actor = pluginProxy
  //   extra = canManageTransfer ? 1 : 0;
  //   extra2 = isAccount ? 1 : 0;
  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4, // salt is ignored in this version. Here for the future
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    if (validFor > 9999999) revert InvalidValidity();
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId][0x00000000].proxyAddress != address(0)) revert PluginAlreadyPlugged();
    uint256 requires = _crunaGuardian().trustedImplementation(_nameId, pluginProxy);
    if (requires == 0 && canManageTransfer && vault().deployedToProduction()) {
      // If requires == 0 the plugin is not trusted, for example during development.
      // If later it is upgraded with a trusted implementation, it won't be possible anymore
      // to upgrade it with a not-trusted version. However, a plugin that starts with an
      // untrusted version can never manage the transfer.
      revert UntrustedImplementationsCanMakeTransfersOnlyOnTestnet();
    }
    if (requires > version()) revert PluginRequiresUpdatedManager(requires);
    _preValidateAndCheckSignature(
      this.plug.selector,
      pluginProxy,
      canManageTransfer ? 1 : 0,
      isERC6551Account ? 1 : 0,
      0,
      timestamp * 1e7 + validFor,
      signature
    );
    address _pluginAddress = vault().deployPlugin(pluginProxy, 0x00000000, tokenId(), isERC6551Account);
    ICrunaPlugin _plugin = ICrunaPlugin(_pluginAddress);
    if (_plugin.nameId() != _nameId) revert InvalidImplementation();
    if (_plugin.isERC6551Account() != isERC6551Account) revert InvalidAccountStatus();
    allPlugins.push(PluginStatus({name: name, active: true, salt: 0x00000000}));
    pluginsById[_nameId][0x00000000] = CrunaPlugin({
      proxyAddress: pluginProxy,
      canManageTransfer: canManageTransfer,
      canBeReset: _plugin.requiresResetOnTransfer(),
      active: true,
      trusted: requires > 0,
      isERC6551Account: isERC6551Account,
      salt: 0x00000000
    });
    _emitPluginStatusChange(name, address(_plugin), true);
  }

  function _emitPluginStatusChange(string memory name, address pluginAddress_, bool status) internal virtual {
    // Avoid to revert if the emission of the event fails.
    // It should never happen, but if it happens, we are
    // notified by the EmitEventFailed event, instead of reverting
    // the entire transaction.
    emit PluginStatusChange(name, pluginAddress_, status);
  }

  function _isPluginAuthorizable(bytes4 _nameId, bytes4 salt) internal view virtual {
    if (pluginsById[_nameId][salt].proxyAddress == address(0)) revert PluginNotFound();
    if (!pluginsById[_nameId][salt].trusted && vault().deployedToProduction())
      revert UntrustedImplementationsCanMakeTransfersOnlyOnTestnet();
    ICrunaPlugin _plugin = plugin(_nameId, salt);
    if (!_plugin.requiresToManageTransfer()) revert NotATransferPlugin();
  }

  // @dev Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
  // the NFT. If the plugins must be blocked for more time, disable it
  function authorizePluginToTransfer(
    string memory name,
    bytes4, // salt is ignored
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    bytes4 salt = 0x00000000;
    if (validFor > 9999999) revert InvalidValidity();
    bytes4 _nameId = _stringToBytes4(name);
    _isPluginAuthorizable(_nameId, salt);
    _preValidateAndCheckSignature(
      this.authorizePluginToTransfer.selector,
      pseudoAddress(name, salt),
      authorized ? 1 : 0,
      timeLock,
      0,
      timestamp * 1e7 + validFor,
      signature
    );
    if (authorized) {
      if (timeLock > 0) revert InvalidTimeLock();
      if (pluginsById[_nameId][salt].canManageTransfer) revert PluginAlreadyAuthorized();
      delete timeLocks[_nameId];
    } else {
      if (!pluginsById[_nameId][salt].canManageTransfer) revert PluginAlreadyUnauthorized();
      if (timeLock == 0 || timeLock > 30 days) revert InvalidTimeLock();
      timeLocks[_nameId] = block.timestamp + timeLock;
    }
    pluginsById[_nameId][salt].canManageTransfer = authorized;
    emit PluginAuthorizationChange(name, pluginAddress(_nameId, salt), authorized, timeLock);
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

  function pluginAddress(bytes4 _nameId, bytes4) public view virtual override returns (address) {
    bytes4 salt = 0x00000000;
    return
      _crunaRegistry().tokenLinkedContract(
        pluginsById[_nameId][salt].proxyAddress,
        salt,
        block.chainid,
        tokenAddress(),
        tokenId()
      );
  }

  function plugin(bytes4 _nameId, bytes4) public view virtual override returns (ICrunaPlugin) {
    return ICrunaPlugin(pluginAddress(_nameId, 0x00000000));
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

  function plugged(string memory name, bytes4) public view virtual returns (bool) {
    bytes4 salt = 0x00000000;
    bytes4 _nameId = _stringToBytes4(name);
    return pluginsById[_nameId][salt].proxyAddress != address(0);
  }

  function pluginIndex(string memory name, bytes4) public view virtual returns (bool, uint256) {
    for (uint256 i = 0; i < allPlugins.length; i++) {
      if (keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(allPlugins[i].name))) {
        return (true, i);
      }
    }
    return (false, 0);
  }

  function isPluginActive(string memory name, bytes4) public view virtual returns (bool) {
    bytes4 salt = 0x00000000;
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_nameId][salt].proxyAddress == address(0)) revert PluginNotFound();
    return pluginsById[_nameId][salt].active;
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

  function pseudoAddress(string memory name, bytes4 _salt) public view virtual returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(name, _salt)))));
  }

  function _isPluginEnabled(string memory name, bytes4 salt) internal view virtual returns (uint256) {
    (bool plugged_, uint256 i) = pluginIndex(name, salt);
    if (!plugged_) revert PluginNotFound();
    if (!allPlugins[i].active) revert PluginAlreadyDisabled();
    return i;
  }

  function _preValidateAndCheckSignature(
    bytes4 selector,
    address actor,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
    uint256 timeValidation,
    bytes calldata signature
  ) internal virtual {
    _validateAndCheckSignature(
      selector,
      owner(),
      actor,
      tokenAddress(),
      tokenId(),
      extra,
      extra2,
      extra3,
      timeValidation,
      signature
    );
  }

  function disablePlugin(
    string memory name,
    bytes4, // salt is ignored
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    bytes4 salt = 0x00000000;
    if (validFor > 9999999) revert InvalidValidity();
    uint256 i = _isPluginEnabled(name, salt);
    _preValidateAndCheckSignature(
      this.disablePlugin.selector,
      pseudoAddress(name, salt),
      resetPlugin ? 1 : 0,
      // in v2 we will user extra2 for the salt, like:
      // uint256(bytes32(salt)),
      // For now, since the salt is defaulted to 0x00000000, we can ignore it.
      0,
      0,
      timestamp * 1e7 + validFor,
      signature
    );
    allPlugins[i].active = false;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId][salt].active = false;
    if (resetPlugin && pluginsById[_nameId][salt].canBeReset) {
      _resetPlugin(_nameId, salt);
    }
    _emitPluginStatusChange(name, pluginAddress(_nameId, salt), false);
  }

  function _isPluginDisabled(string memory name, bytes4 salt) internal view virtual returns (uint256) {
    (bool plugged_, uint256 i) = pluginIndex(name, salt);
    if (!plugged_) revert PluginNotFound();
    if (allPlugins[i].active) revert PluginNotDisabled();
    return i;
  }

  function reEnablePlugin(
    string memory name,
    bytes4, // salt is ignored
    bool resetPlugin,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner nonReentrant {
    bytes4 salt = 0x00000000;
    if (validFor > 9999999) revert InvalidValidity();
    uint256 i = _isPluginDisabled(name, salt);
    _preValidateAndCheckSignature(
      this.reEnablePlugin.selector,
      pseudoAddress(name, salt),
      resetPlugin ? 1 : 0,
      0,
      0,
      timestamp * 1e7 + validFor,
      signature
    );
    allPlugins[i].active = true;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_nameId][salt].active = true;
    if (resetPlugin && pluginsById[_nameId][salt].canBeReset) {
      _resetPlugin(_nameId, salt);
    }
    _emitPluginStatusChange(name, pluginAddress(_nameId, salt), true);
  }

  function _resetPlugin(bytes4 _nameId, bytes4) internal virtual {
    ICrunaPlugin _plugin = plugin(_nameId, 0x00000000);
    _plugin.reset();
  }

  function _removeLockIfExpired(bytes4 _nameId, bytes4) internal virtual {
    bytes4 salt = 0x00000000;
    if (timeLocks[_nameId] < block.timestamp) {
      delete timeLocks[_nameId];
      pluginsById[_nameId][salt].canManageTransfer = true;
    }
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by authorized plugins
  function managedTransfer(bytes4 pluginNameId, uint256 tokenId, address to) external virtual override nonReentrant {
    bytes4 salt = 0x00000000;
    // In v2, we will find the plugin, instead of defaulting to 0x00000000
    if (pluginsById[pluginNameId][salt].proxyAddress == address(0) || !pluginsById[pluginNameId][salt].active)
      revert PluginNotFoundOrDisabled();
    if (pluginAddress(pluginNameId, salt) != _msgSender()) revert NotTheAuthorizedPlugin();
    _removeLockIfExpired(pluginNameId, salt);
    if (!pluginsById[pluginNameId][salt].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
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
        pluginsById[_nameId][allPlugins[i].salt].active = false;
        if (pluginsById[_nameId][allPlugins[i].salt].canBeReset) _resetPlugin(_nameId, allPlugins[i].salt);
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
    _preValidateAndCheckSignature(this.protectedTransfer.selector, to, 0, 0, 0, timestamp * 1e7 + validFor, signature);
    _resetActorsAndDisablePlugins();
    vault().managedTransfer(nameId(), tokenId, to);
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
