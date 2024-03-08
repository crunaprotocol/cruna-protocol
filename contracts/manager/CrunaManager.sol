// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Actor} from "./Actor.sol";
import {CrunaManagerBase} from "./CrunaManagerBase.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {ExcessivelySafeCall} from "../libs/ExcessivelySafeCall.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CrunaPluginBase} from "../plugins/CrunaPluginBase.sol";

// import {console} from "hardhat/console.sol";

contract CrunaManager is Actor, CrunaManagerBase, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;
  using ExcessivelySafeCall for address;

  uint256 private constant _MAX_ACTORS = 16;
  bytes4 private constant _PROTECTOR = 0x245ac14a; // bytes4(keccak256("PROTECTOR"));
  bytes4 private constant _SAFE_RECIPIENT = 0xb58bf73a; //bytes4(keccak256("SAFE_RECIPIENT"));

  PluginElement[] public allPlugins;

  mapping(bytes8 => CrunaPlugin) public pluginsById;
  mapping(bytes8 => uint256) public timeLocks;

  function migrate(uint256) external virtual override {
    if (_msgSender() != address(this)) revert Forbidden();
    // nothing, for now
  }

  function nameId() public view virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaManager"));
  }

  /// @dev Counts the protectors.
  function countActiveProtectors() public view virtual override returns (uint256) {
    return _actors[_PROTECTOR].length;
  }

  /// @dev Find a specific protector
  function findProtectorIndex(address protector_) public view virtual override returns (uint256) {
    return actorIndex(protector_, _PROTECTOR);
  }

  /// @dev Returns true if the address is a protector.
  /// @param protector_ The protector address.
  function isAProtector(address protector_) public view virtual override returns (bool) {
    return _isActiveActor(protector_, _PROTECTOR);
  }

  /// @dev Returns the list of protectors.
  function listProtectors() public view virtual override returns (address[] memory) {
    return getActors(_PROTECTOR);
  }

  function hasProtectors() public view virtual override returns (bool) {
    return actorCount(_PROTECTOR) != 0;
  }

  function isTransferable(address to) external view override returns (bool) {
    return !hasProtectors() || isSafeRecipient(to);
  }

  function locked() external view override returns (bool) {
    return hasProtectors();
  }

  function version() public pure virtual override returns (uint256) {
    // 1.0.1
    return 1_000_001;
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
      _PROTECTOR,
      protector_,
      status,
      timestamp + (_TIME_VALIDATION_MULTIPLIER / _TIMESTAMP_MULTIPLIER),
      validFor,
      signature,
      _msgSender()
    );
    emit ProtectorChange(protector_, status);
    _emitLockeEvent(countActiveProtectors(), status);
  }

  function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual override onlyTokenOwner {
    if (actorCount(_PROTECTOR) != 0) revert ProtectorsAlreadySet();
    if (actorCount(_SAFE_RECIPIENT) != 0) revert SafeRecipientsAlreadySet();
    if (otherTokenId == tokenId()) revert CannotimportProtectorsAndSafeRecipientsFromYourself();
    if (_vault().ownerOf(otherTokenId) != owner()) revert NotTheSameOwner();
    CrunaManager otherManager = CrunaManager(_vault().managerOf(otherTokenId));
    if (otherManager.actorCount(_PROTECTOR) == 0 && otherManager.actorCount(_SAFE_RECIPIENT) == 0) revert NothingToImport();
    address[] memory otherProtectors = otherManager.getProtectors();
    uint256 len = otherProtectors.length;
    for (uint256 i; i < len; ) {
      if (otherProtectors[i] == address(0)) revert ZeroAddress();
      if (otherProtectors[i] == _msgSender()) revert CannotBeYourself();
      _addActor(otherProtectors[i], _PROTECTOR);
      unchecked {
        i++;
      }
    }
    address[] memory otherSafeRecipients = otherManager.getSafeRecipients();
    len = otherSafeRecipients.length;
    for (uint256 i; i < len; ) {
      _addActor(otherSafeRecipients[i], _SAFE_RECIPIENT);
      unchecked {
        i++;
      }
    }
    emit ProtectorsAndSafeRecipientsImported(otherProtectors, otherSafeRecipients, otherTokenId);
    _emitLockeEvent(1, true);
  }

  // @dev see {ICrunaManager.sol-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return getActors(_PROTECTOR);
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
      _SAFE_RECIPIENT,
      recipient,
      status,
      timestamp,
      validFor,
      signature,
      _msgSender()
    );
    emit SafeRecipientChange(recipient, status);
  }

  // @dev see {ICrunaManager.sol-isSafeRecipient}
  function isSafeRecipient(address recipient) public view virtual override returns (bool) {
    return actorIndex(recipient, _SAFE_RECIPIENT) != _MAX_ACTORS;
  }

  // @dev see {ICrunaManager.sol-getSafeRecipients}
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return getActors(_SAFE_RECIPIENT);
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
    address proxyAddress_,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4, // salt is ignored in this version. Here for the future
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    if (allPlugins.length == 16) {
      // We do not allow more than 16 plugins to avoid risks of going out-of-gas while
      // looping through allPlugins.
      revert PluginNumberOverflow();
    }
    bytes4 _nameId = _stringToBytes4(name);
    if (pluginsById[_combineBytes4(_nameId, _BYTES4_ZERO)].proxyAddress != address(0)) revert PluginAlreadyPlugged();
    uint256 requires = _crunaGuardian().trustedImplementation(_nameId, proxyAddress_);
    if (requires == 0 && canManageTransfer && !_vault().allowUntrustedTransfers()) {
      // If requires == 0 the plugin is not trusted, for example during development.
      // If later it is upgraded with a trusted implementation, it can be explicitly trusted using trustPlugin.
      revert UntrustedImplementationsNotAllowedToMakeTransfers();
    }
    if (requires > version()) revert PluginRequiresUpdatedManager(requires);
    _preValidateAndCheckSignature(
      this.plug.selector,
      proxyAddress_,
      canManageTransfer ? 1 : 0,
      isERC6551Account ? 1 : 0,
      timestamp,
      validFor,
      signature
    );
    // If the plugin has been plugged before and later unplugged, the proxy won't be deployed again
    // but the existing address will be returned by the registry.
    address _pluginAddress = _vault().deployPlugin(proxyAddress_, _BYTES4_ZERO, tokenId(), isERC6551Account);
    CrunaPluginBase _plugin = CrunaPluginBase(payable(_pluginAddress));
    if (_plugin.nameId() != _nameId) revert InvalidImplementation();
    if (_plugin.isERC6551Account() != isERC6551Account) revert InvalidAccountStatus();
    allPlugins.push(PluginElement({name: name, active: true, salt: _BYTES4_ZERO}));
    pluginsById[_combineBytes4(_nameId, _BYTES4_ZERO)] = CrunaPlugin({
      proxyAddress: proxyAddress_,
      canManageTransfer: canManageTransfer,
      canBeReset: _plugin.requiresResetOnTransfer(),
      active: true,
      trusted: requires != 0,
      isERC6551Account: isERC6551Account,
      salt: _BYTES4_ZERO
    });
    emit PluginStatusChange(name, _BYTES4_ZERO, address(_plugin), PluginStatus.PluggedAndActive);
  }

  function unplug(
    string memory name,
    bytes4,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    bytes4 salt = _BYTES4_ZERO;
    bytes4 _nameId = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    _preValidateAndCheckSignature(
      this.unplug.selector,
      pseudoAddress(name, salt),
      0,
      // in v2 we will user extra3 for the salt, like:
      // uint256(bytes32(salt)),
      // For now, since the salt is defaulted to _BYTES4_ZERO, we can ignore it.
      0,
      timestamp,
      validFor,
      signature
    );
    uint256 len = allPlugins.length;
    for (uint256 i; i < len; ) {
      unchecked {
        if (_hashString(allPlugins[i].name) == _hashString(name)) {
          if (pluginsById[_key].canBeReset) {
            _resetPlugin(_nameId, salt);
          }
          allPlugins[i] = allPlugins[allPlugins.length - 1];
          allPlugins.pop();
          break;
        }
        i++;
      }
    }
    delete pluginsById[_key];
    emit PluginStatusChange(name, salt, pluginAddress(_nameId, salt), PluginStatus.Unplugged);
  }

  // To set as trusted a plugin that initially was not trusted
  // No need for extra protection because the CrunaGuardian absolves that role
  function trustPlugin(string memory name, bytes4) external virtual override onlyTokenOwner {
    bytes4 salt = _BYTES4_ZERO;
    bytes4 _nameId = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (pluginsById[_key].trusted) revert PluginAlreadyTrusted();
    if (_crunaGuardian().trustedImplementation(_nameId, pluginsById[_key].proxyAddress) != 0) {
      pluginsById[_key].trusted = true;
      emit PluginTrusted(name, salt);
    } else revert StillUntrusted();
  }

  // @dev Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
  // the NFT. If the plugins must be blocked for more time, disable it at your peril of making it useless.
  function authorizePluginToTransfer(
    string memory name,
    bytes4, // salt is ignored
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    bytes4 salt = _BYTES4_ZERO;

    bytes4 _nameId = _stringToBytes4(name);
    _isPluginAuthorizable(_nameId, salt);
    _preValidateAndCheckSignature(
      this.authorizePluginToTransfer.selector,
      pseudoAddress(name, salt),
      authorized ? 1 : 0,
      timeLock,
      timestamp,
      validFor,
      signature
    );
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (authorized) {
      if (timeLock != 0) revert InvalidTimeLock();
      if (pluginsById[_key].canManageTransfer) revert PluginAlreadyAuthorized();
      delete timeLocks[_key];
    } else {
      if (timeLock == 0 || timeLock > 30 days) revert InvalidTimeLock();
      if (!pluginsById[_key].canManageTransfer) revert PluginAlreadyUnauthorized();
      timeLocks[_key] = block.timestamp + timeLock;
    }
    pluginsById[_key].canManageTransfer = authorized;
    emit PluginAuthorizationChange(name, salt, pluginAddress(_nameId, salt), authorized, timeLock);
  }

  function pluginAddress(bytes4 _nameId, bytes4) public view virtual override returns (address payable) {
    bytes4 salt = _BYTES4_ZERO;
    return
      payable(
        _crunaRegistry().tokenLinkedContract(
          pluginsById[_combineBytes4(_nameId, salt)].proxyAddress,
          salt,
          block.chainid,
          tokenAddress(),
          tokenId()
        )
      );
  }

  function plugin(bytes4 _nameId, bytes4) public view virtual override returns (CrunaPluginBase) {
    return CrunaPluginBase(pluginAddress(_nameId, _BYTES4_ZERO));
  }

  function countPlugins() public view virtual override returns (uint256, uint256) {
    uint256 active;
    uint256 disabled;
    uint256 len = allPlugins.length;
    for (uint256 i; i < len; ) {
      unchecked {
        if (allPlugins[i].active) active++;
        else disabled++;
        i++;
      }
    }
    return (active, disabled);
  }

  function plugged(string memory name, bytes4) public view virtual returns (bool) {
    bytes4 salt = _BYTES4_ZERO;
    bytes4 _nameId = _stringToBytes4(name);
    return pluginsById[_combineBytes4(_nameId, salt)].proxyAddress != address(0);
  }

  function pluginIndex(string memory name, bytes4) public view virtual returns (bool, uint256) {
    uint256 len = allPlugins.length;
    for (uint256 i; i < len; ) {
      if (_hashString(name) == _hashString(allPlugins[i].name)) {
        return (true, i);
      }
      unchecked {
        i++;
      }
    }
    return (false, 0);
  }

  function isPluginActive(string memory name, bytes4) public view virtual returns (bool) {
    bytes4 salt = _BYTES4_ZERO;
    bytes4 _nameId = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    return pluginsById[_key].active;
  }

  function listPlugins(bool active) external view virtual returns (string[] memory) {
    (uint256 actives, uint256 disabled) = countPlugins();
    string[] memory _plugins = new string[](active ? actives : disabled);
    uint256 len = allPlugins.length;
    for (uint256 i; i < len; ) {
      if (allPlugins[i].active == active) {
        _plugins[i] = allPlugins[i].name;
      }

      unchecked {
        i++;
      }
    }
    return _plugins;
  }

  /**
   * @dev It returns a pseudo address created from the name of a plugin and the salt used to deploy it.
   * Notice that abi.encodePacked does not risk to create collisions because the salt is a bytes4.
   */
  function pseudoAddress(string memory name, bytes4 _salt) public view virtual returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(name, _salt)))));
  }

  function disablePlugin(
    string memory name,
    bytes4, // salt is ignored
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    bytes4 salt = _BYTES4_ZERO;

    uint256 i = _isPluginEnabled(name, salt);
    _preValidateAndCheckSignature(this.disablePlugin.selector, pseudoAddress(name, salt), 0, 0, timestamp, validFor, signature);
    delete allPlugins[i].active;
    bytes4 _nameId = _stringToBytes4(name);
    delete pluginsById[_combineBytes4(_nameId, salt)].active;
    emit PluginStatusChange(name, salt, pluginAddress(_nameId, salt), PluginStatus.PluggedAndInactive);
  }

  function reEnablePlugin(
    string memory name,
    bytes4, // salt is ignored
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    bytes4 salt = _BYTES4_ZERO;

    uint256 i = _isPluginDisabled(name, salt);
    _preValidateAndCheckSignature(
      this.reEnablePlugin.selector,
      pseudoAddress(name, salt),
      0,
      0,
      timestamp,
      validFor,
      signature
    );
    allPlugins[i].active = true;
    bytes4 _nameId = _stringToBytes4(name);
    pluginsById[_combineBytes4(_nameId, salt)].active = true;
    emit PluginStatusChange(name, salt, pluginAddress(_nameId, salt), PluginStatus.PluggedAndActive);
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by authorized plugins
  function managedTransfer(bytes4 pluginNameId, address to) external virtual override nonReentrant {
    // In v2, we will find the plugin, instead of defaulting to _BYTES4_ZERO
    bytes4 salt = _BYTES4_ZERO;
    bytes8 _key = _combineBytes4(pluginNameId, salt);
    if (pluginsById[_key].proxyAddress == address(0) || !pluginsById[_key].active) revert PluginNotFoundOrDisabled();
    if (pluginAddress(pluginNameId, salt) != _msgSender()) revert NotTheAuthorizedPlugin();
    _removeLockIfExpired(pluginNameId, salt);
    if (!pluginsById[_key].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();

    if (!pluginsById[_key].trusted && !_vault().allowUntrustedTransfers())
      revert UntrustedImplementationsNotAllowedToMakeTransfers();
    _resetActorsAndPlugins();
    // In theory, the vault may revert, blocking the entire process
    // We allow it, assuming that the vault implementation has the
    // right to set up more advanced rules, before allowing the transfer,
    // despite the plugin has the ability to do so.
    _vault().managedTransfer(pluginNameId, tokenId(), to);
  }

  function protectedTransfer(
    uint256 tokenId,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    _preValidateAndCheckSignature(this.protectedTransfer.selector, to, 0, 0, timestamp, validFor, signature);
    _resetActorsAndPlugins();
    _vault().managedTransfer(nameId(), tokenId, to);
  }

  function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8) {
    return bytes8(bytes32(a) | (bytes32(b) >> 32));
  }

  function _isProtected() internal view virtual override returns (bool) {
    return actorCount(_PROTECTOR) != 0;
  }

  function _isProtector(address protector_) internal view virtual override returns (bool) {
    return _isActiveActor(protector_, _PROTECTOR);
  }

  // from SignatureValidator
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual override returns (bool) {
    if (_actors[_PROTECTOR].length == 0) {
      // if there are no protectors, the signer can pre-approve its own candidate
      return selector == this.setProtector.selector && actor == signer;
    }
    return _isActiveActor(signer, _PROTECTOR);
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
    address sender
  ) internal virtual {
    if (actor == address(0)) revert ZeroAddress();
    if (actor == sender) revert CannotBeYourself();
    _preValidateAndCheckSignature(_functionSelector, actor, status ? 1 : 0, 0, timestamp, validFor, signature);
    if (!status) {
      if (timestamp != 0 && timestamp > _TIME_VALIDATION_MULTIPLIER - 1 && !isAProtector(actor)) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0 && timestamp > _TIME_VALIDATION_MULTIPLIER - 1 && isAProtector(actor))
        revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  function _isPluginAuthorizable(bytes4 _nameId, bytes4 salt) internal view virtual {
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (!pluginsById[_key].trusted && !_vault().allowUntrustedTransfers())
      revert UntrustedImplementationsNotAllowedToMakeTransfers();
    CrunaPluginBase _plugin = plugin(_nameId, salt);
    if (!_plugin.requiresToManageTransfer()) revert NotATransferPlugin();
  }

  function _emitLockeEvent(uint256 protectorsCount, bool status) internal virtual {
    if ((status && protectorsCount == 1) || (!status && protectorsCount == 0)) {
      // Avoid to revert if the emission of the event fails.
      // It should never happen, but if it happens, we are
      // notified by the EmitLockedEventFailed event, instead of reverting
      // the entire transaction.
      address vaultAddress = address(_vault());
      // solhint-disable-next-line avoid-low-level-calls
      (bool success, ) = vaultAddress.excessivelySafeCall(
        10_000,
        0,
        32,
        abi.encodeWithSignature("emitLockedEvent(uint256,bool)", tokenId(), status && protectorsCount == 1)
      );
      if (!success) {
        // we emit a local event to alert. Not ideal, but better than reverting
        emit EmitLockedEventFailed();
      }
    }
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
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) internal virtual {
    if (validFor > _MAX_VALID_FOR) revert InvalidValidity();
    _validateAndCheckSignature(
      selector,
      owner(),
      actor,
      tokenAddress(),
      tokenId(),
      extra,
      extra2,
      0,
      timestamp * _TIMESTAMP_MULTIPLIER + validFor,
      signature
    );
  }

  function _isPluginDisabled(string memory name, bytes4 salt) internal view virtual returns (uint256) {
    (bool plugged_, uint256 i) = pluginIndex(name, salt);
    if (!plugged_) revert PluginNotFound();
    if (allPlugins[i].active) revert PluginNotDisabled();
    return i;
  }

  function _resetPlugin(bytes4 _nameId, bytes4) internal virtual {
    bytes4 salt = _BYTES4_ZERO;
    address plugin_ = pluginAddress(_nameId, salt);
    // A plugin resetting should spend very little gas because it mostly has to delete
    // stored data, and they would return gas back. 10_000 is a conservative amount of gas.
    // Any plugin needing more gas won't be trusted by the CrunaGuardian.
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = plugin_.excessivelySafeCall(10_000, 0, 32, abi.encodeWithSignature("reset()"));
    // Optionally log success/failure
    emit PluginResetAttempt(_nameId, salt, success);
  }

  function _removeLockIfExpired(bytes4 _nameId, bytes4) internal virtual {
    bytes4 salt = _BYTES4_ZERO;
    bytes8 _key = _combineBytes4(_nameId, salt);
    if (timeLocks[_key] < block.timestamp) {
      delete timeLocks[_key];
      pluginsById[_key].canManageTransfer = true;
    }
  }

  function _resetActorsAndPlugins() internal virtual {
    _deleteActors(_PROTECTOR);
    _deleteActors(_SAFE_RECIPIENT);
    // disable all plugins
    uint256 len = allPlugins.length;
    for (uint256 i; i < len; ) {
      bytes4 _nameId = _stringToBytes4(allPlugins[i].name);
      // We reset the plugin only if it requires it. In theory, this could consume a lot of gas and
      // cause a revert of the entire process, but there is no other way to do it, because during a
      // transfer, resettable plugins must be reset.
      // It is responsibility of the user to plug only plugins that have been audited and trusted.
      if (pluginsById[_combineBytes4(_nameId, allPlugins[i].salt)].canBeReset) _resetPlugin(_nameId, allPlugins[i].salt);
      unchecked {
        i++;
      }
    }
    emit Reset();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
