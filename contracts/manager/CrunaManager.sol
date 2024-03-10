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
import {Canonical} from "../libs/Canonical.sol";
import {ManagerConstants} from "../libs/ManagerConstants.sol";

//import {console} from "hardhat/console.sol";

contract CrunaManager is Actor, CrunaManagerBase, ReentrancyGuard {
  using ECDSA for bytes32;
  using Strings for uint256;
  using ExcessivelySafeCall for address;

  PluginElement[] private _allPlugins;
  mapping(bytes8 => CrunaPlugin) private _pluginByKey;

  error IndexOutOfBounds();

  function pluginByKey(bytes8 key) external view returns (CrunaPlugin memory) {
    return _pluginByKey[key];
  }

  function allPlugins() external view returns (PluginElement[] memory) {
    return _allPlugins;
  }

  function pluginByIndex(uint256 index) external view returns (PluginElement memory) {
    if (index >= _allPlugins.length) revert IndexOutOfBounds();
    return _allPlugins[index];
  }

  // This is here for the future
  function migrate(uint256) external virtual override {
    if (_msgSender() != address(this)) revert Forbidden();
    // nothing, for now
  }

  /// @dev Counts the protectors.
  function countActiveProtectors() external view virtual override returns (uint256) {
    return _actors[ManagerConstants.protectorId()].length;
  }

  /// @dev Find a specific protector
  function findProtectorIndex(address protector_) external view virtual override returns (uint256) {
    return _actorIndex(protector_, ManagerConstants.protectorId());
  }

  /// @dev Returns true if the address is a protector.
  /// @param protector_ The protector address.
  function isProtector(address protector_) external view virtual override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  function hasProtectors() external view virtual override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  function isTransferable(address to) external view override returns (bool) {
    return
      _actors[ManagerConstants.protectorId()].length == 0 ||
      _actorIndex(to, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  function locked() external view override returns (bool) {
    return _actors[ManagerConstants.protectorId()].length != 0;
  }

  function version() external pure virtual override returns (uint256) {
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
      ManagerConstants.protectorId(),
      protector_,
      status,
      timestamp + (_TIME_VALIDATION_MULTIPLIER / _TIMESTAMP_MULTIPLIER),
      validFor,
      signature,
      _msgSender()
    );
    emit ProtectorChange(protector_, status);
    _emitLockeEvent(_actors[ManagerConstants.protectorId()].length, status);
  }

  function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual override onlyTokenOwner {
    if (_actorCount(ManagerConstants.protectorId()) != 0) revert ProtectorsAlreadySet();
    if (_actorCount(ManagerConstants.safeRecipientId()) != 0) revert SafeRecipientsAlreadySet();
    if (otherTokenId == tokenId()) revert CannotImportProtectorsAndSafeRecipientsFromYourself();
    if (_vault().ownerOf(otherTokenId) != owner()) revert NotTheSameOwner();
    CrunaManager otherManager = CrunaManager(_vault().managerOf(otherTokenId));
    if (otherManager.countProtectors() == 0)
      if (otherManager.countSafeRecipients() == 0) revert NothingToImport();
    address[] memory otherProtectors = otherManager.getProtectors();
    uint256 len = otherProtectors.length;
    for (uint256 i; i < len; ) {
      if (otherProtectors[i] == address(0)) revert ZeroAddress();
      if (otherProtectors[i] == _msgSender()) revert CannotBeYourself();
      _addActor(otherProtectors[i], ManagerConstants.protectorId());
      unchecked {
        ++i;
      }
    }
    address[] memory otherSafeRecipients = otherManager.getSafeRecipients();
    len = otherSafeRecipients.length;
    for (uint256 i; i < len; ) {
      _addActor(otherSafeRecipients[i], ManagerConstants.safeRecipientId());
      unchecked {
        ++i;
      }
    }
    emit ProtectorsAndSafeRecipientsImported(otherProtectors, otherSafeRecipients, otherTokenId);
    _emitLockeEvent(1, true);
  }

  // @dev see {ICrunaManager.sol-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.protectorId());
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
      ManagerConstants.safeRecipientId(),
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
  function isSafeRecipient(address recipient) external view virtual override returns (bool) {
    return _actorIndex(recipient, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  // @dev see {ICrunaManager.sol-getSafeRecipients}
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.safeRecipientId());
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
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    if (_allPlugins.length == 16) {
      // We do not allow more than 16 plugins to avoid risks of going out-of-gas while
      // looping through allPlugins.
      revert PluginNumberOverflow();
    }
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress != address(0) && !_pluginByKey[_key].unplugged) revert PluginAlreadyPlugged();
    uint256 requires = Canonical.crunaGuardian().trustedImplementation(nameId_, proxyAddress_);
    if (requires == 0)
      if (canManageTransfer)
        if (!_vault().allowUntrustedTransfers()) {
          // If requires == 0 the plugin is not trusted, for example during development.
          // If later it is upgraded with a trusted implementation, it can be explicitly trusted using trustPlugin.
          revert UntrustedImplementationsNotAllowedToMakeTransfers();
        }
    if (requires > _version()) revert PluginRequiresUpdatedManager(requires);
    _preValidateAndCheckSignature(
      this.plug.selector,
      proxyAddress_,
      canManageTransfer ? 1 : 0,
      isERC6551Account ? 1 : 0,
      timestamp,
      validFor,
      signature
    );
    if (_pluginByKey[_key].banned) revert PluginHasBeenMarkedAsNotPluggable();
    _plug(name, proxyAddress_, canManageTransfer, isERC6551Account, nameId_, salt, _key, requires);
  }

  function _plug(
    string memory name,
    address proxyAddress_,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4 nameId_,
    bytes4 salt,
    bytes8 _key,
    uint256 requires
  ) internal {
    // If the plugin has been plugged before and later unplugged, the proxy won't be deployed again
    // but the existing address will be returned by the registry.
    address pluginAddress_ = _vault().deployPlugin(proxyAddress_, salt, tokenId(), isERC6551Account);
    CrunaPluginBase plugin_ = CrunaPluginBase(payable(pluginAddress_));
    if (plugin_.nameId() != nameId_) revert InvalidImplementation();
    if (plugin_.isERC6551Account() != isERC6551Account) revert InvalidAccountStatus();
    plugin_.init();
    _allPlugins.push(PluginElement({active: true, salt: salt, nameId: nameId_}));
    if (_pluginByKey[_key].unplugged) {
      if (_pluginByKey[_key].proxyAddress != proxyAddress_) revert InconsistentProxyAddresses();
    }
    _pluginByKey[_key] = CrunaPlugin({
      proxyAddress: proxyAddress_,
      salt: salt,
      timeLock: 0,
      canManageTransfer: canManageTransfer,
      canBeReset: plugin_.requiresResetOnTransfer(),
      active: true,
      isERC6551Account: isERC6551Account,
      trusted: requires != 0,
      banned: false,
      unplugged: false
    });
    emit PluginStatusChange(name, salt, pluginAddress_, uint256(PluginChange.Plug));
  }

  function changePluginStatus(
    string memory name,
    bytes4 salt,
    PluginChange change,
    uint256 timeLock_,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    (bool plugged_, uint256 i) = _pluginIndex(nameId_, salt);
    if (!plugged_) revert PluginNotFound();
    _preValidateAndCheckSignature(
      this.changePluginStatus.selector,
      _pseudoAddress(name, salt),
      uint256(change),
      timeLock_,
      timestamp,
      validFor,
      signature
    );
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (change == PluginChange.Disable) {
      _disablePlugin(i, _key);
    } else if (change == PluginChange.ReEnable) {
      _reEnablePlugin(i, _key);
    } else if (change == PluginChange.Authorize || change == PluginChange.DeAuthorize) {
      emit PluginStatusChange(name, salt, _pluginAddress(nameId_, salt), timeLock_ * 1e3 + uint256(change));
      _authorizePluginToTransfer(nameId_, salt, _key, change, timeLock_);
      return;
    } else if (change == PluginChange.Unplug || change == PluginChange.UnplugForever) {
      emit PluginStatusChange(name, salt, _pluginAddress(nameId_, salt), uint256(change));
      _unplugPlugin(i, nameId_, salt, _key, change);
      return;
    } else if (change == PluginChange.Reset) {
      _resetPlugin(nameId_, salt);
    } else revert UnsupportedPluginChange();
    emit PluginStatusChange(name, salt, _pluginAddress(nameId_, salt), uint256(change));
  }

  // To set as trusted a plugin that initially was not trusted
  // No need for extra protection because the CrunaGuardian absolves that role
  function trustPlugin(string memory name, bytes4 salt) external virtual override onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (_pluginByKey[_key].trusted) revert PluginAlreadyTrusted();
    if (Canonical.crunaGuardian().trustedImplementation(nameId_, _pluginByKey[_key].proxyAddress) != 0) {
      _pluginByKey[_key].trusted = true;
      emit PluginTrusted(name, salt);
    } else revert StillUntrusted();
  }

  function pluginAddress(bytes4 nameId_, bytes4 salt) external view virtual override returns (address payable) {
    return _pluginAddress(nameId_, salt);
  }

  function plugin(bytes4 nameId_, bytes4 salt) external view virtual override returns (CrunaPluginBase) {
    return _plugin(nameId_, salt);
  }

  function countPlugins() external view virtual override returns (uint256, uint256) {
    return _countPlugins();
  }

  function plugged(string memory name, bytes4 salt) external view virtual returns (bool) {
    bytes4 nameId_ = _stringToBytes4(name);
    return _pluginByKey[_combineBytes4(nameId_, salt)].proxyAddress != address(0);
  }

  function pluginIndex(string memory name, bytes4 salt) external view virtual returns (bool, uint256) {
    return _pluginIndex(_stringToBytes4(name), salt);
  }

  function isPluginActive(string memory name, bytes4 salt) external view virtual returns (bool) {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress == address(0)) revert PluginNotFound();
    return _pluginByKey[_key].active;
  }

  /// @dev returns the list of plugins' keys
  /// It is responsibility of the app calling for this function to know the names of all the plugins
  /// In the future it would be good to have an official registry of all plugins to be able to reverse
  /// from the nameId to the name as a string.
  function listPluginsKeys(bool active) external view virtual returns (bytes8[] memory) {
    (uint256 actives, uint256 disabled) = _countPlugins();
    bytes8[] memory _keys = new bytes8[](active ? actives : disabled);
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement memory plugin_ = _allPlugins[i];
      if (plugin_.active == active) {
        _keys[i] = _combineBytes4(plugin_.nameId, plugin_.salt);
      }
      unchecked {
        ++i;
      }
    }
    return _keys;
  }

  /**
   * @dev It returns a pseudo address created from the name of a plugin and the salt used to deploy it.
   * Notice that abi.encodePacked does not risk to create collisions because the salt is a bytes4.
   */
  function pseudoAddress(string memory name, bytes4 _salt) external view virtual returns (address) {
    return _pseudoAddress(name, _salt);
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by authorized plugins
  function managedTransfer(bytes4 pluginNameId, address to) external virtual override nonReentrant {
    (bytes8 _key, bytes4 salt) = _getKeyAndSalt(pluginNameId);
    if (_key == bytes8(0) || !_pluginByKey[_key].active) revert PluginNotFoundOrDisabled();
    if (_pluginAddress(pluginNameId, salt) != _msgSender()) revert NotTheAuthorizedPlugin();
    _removeLockIfExpired(pluginNameId, salt);
    if (!_pluginByKey[_key].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
    if (!_pluginByKey[_key].trusted)
      if (!_vault().allowUntrustedTransfers()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    _resetOnTransfer(pluginNameId, salt);
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
    _resetOnTransfer(bytes4(0), bytes4(0));
    _vault().managedTransfer(_nameId(), tokenId, to);
  }

  function _plugin(bytes4 nameId_, bytes4 salt) internal view virtual returns (CrunaPluginBase) {
    return CrunaPluginBase(_pluginAddress(nameId_, salt));
  }

  function _pluginAddress(bytes4 nameId_, bytes4 salt) internal view virtual returns (address payable) {
    return
      payable(
        Canonical.crunaRegistry().tokenLinkedContract(
          _pluginByKey[_combineBytes4(nameId_, salt)].proxyAddress,
          salt,
          block.chainid,
          tokenAddress(),
          tokenId()
        )
      );
  }

  function _nameId() internal view virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaManager"));
  }

  function _pseudoAddress(string memory name, bytes4 _salt) internal view virtual returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(name, _salt)))));
  }

  function _countPlugins() internal view virtual returns (uint256, uint256) {
    uint256 active;
    uint256 disabled;
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      unchecked {
        if (_allPlugins[i].active) active++;
        else disabled++;
        ++i;
      }
    }
    return (active, disabled);
  }

  function _disablePlugin(uint256 i, bytes8 _key) internal {
    if (!_allPlugins[i].active) revert PluginAlreadyDisabled();
    delete _allPlugins[i].active;
    delete _pluginByKey[_key].active;
  }

  function _reEnablePlugin(uint256 i, bytes8 _key) internal {
    if (_allPlugins[i].active) revert PluginNotDisabled();
    _allPlugins[i].active = true;
    _pluginByKey[_key].active = true;
  }

  function _unplugPlugin(uint256 i, bytes4 nameId_, bytes4 salt, bytes8 _key, PluginChange change) internal {
    if (_pluginByKey[_key].canBeReset) {
      if (change == PluginChange.UnplugForever) {
        // The plugin is somehow hostile (for example cause reverts trying to reset it)
        // We mark it as no not pluggable, to avoid re-plugging it in the future.
        // Notice that the same type of plugin can still be plugged using a different salt.
        _pluginByKey[_key].banned = true;
      } else {
        // resets the plugin
        _resetPlugin(nameId_, salt);
      }
    }
    // _allPlugins.length is > 0 because we are unplugging an existing plugin
    if (i != _allPlugins.length - 1) {
      _allPlugins[i] = _allPlugins[_allPlugins.length - 1];
    }
    _allPlugins.pop();
    _pluginByKey[_key].unplugged = true;
  }

  // @dev Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
  // the NFT. If the plugins must be blocked for more time, disable it at your peril of making it useless.
  function _authorizePluginToTransfer(
    bytes4 nameId_,
    bytes4 salt,
    bytes8 _key,
    PluginChange change,
    uint256 timeLock
  ) internal virtual {
    if (!_pluginByKey[_key].trusted)
      if (!_vault().allowUntrustedTransfers()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    CrunaPluginBase plugin_ = _plugin(nameId_, salt);
    if (!plugin_.requiresToManageTransfer()) revert NotATransferPlugin();
    if (change == PluginChange.Authorize) {
      if (timeLock != 0) revert InvalidTimeLock();
      if (_pluginByKey[_key].canManageTransfer) revert PluginAlreadyAuthorized();
      delete _pluginByKey[_key].timeLock;
      _pluginByKey[_key].canManageTransfer = true;
    } else {
      // more gas efficient than using an || operator
      if (timeLock == 0) revert InvalidTimeLock();
      if (timeLock > 30 days) revert InvalidTimeLock();
      if (!_pluginByKey[_key].canManageTransfer) revert PluginAlreadyUnauthorized();
      _pluginByKey[_key].timeLock = uint32(block.timestamp + timeLock);
      delete _pluginByKey[_key].canManageTransfer;
    }
  }

  function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8) {
    return bytes8(bytes32(a) | (bytes32(b) >> 32));
  }

  function _isProtected() internal view virtual override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  function countProtectors() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.protectorId());
  }

  function countSafeRecipients() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.safeRecipientId());
  }

  function _isProtector(address protector_) internal view virtual override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  // from SignatureValidator
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual override returns (bool) {
    if (_actors[ManagerConstants.protectorId()].length == 0) {
      // if there are no protectors, the signer can pre-approve its own candidate
      return selector == this.setProtector.selector && actor == signer;
    }
    return _isActiveActor(signer, ManagerConstants.protectorId());
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
      if (timestamp != 0)
        if (timestamp > _TIME_VALIDATION_MULTIPLIER - 1)
          if (!_isActiveActor(actor, ManagerConstants.protectorId())) revert ProtectorNotFound();
      _removeActor(actor, role_);
    } else {
      if (timestamp != 0)
        if (timestamp > _TIME_VALIDATION_MULTIPLIER - 1)
          if (_isActiveActor(actor, ManagerConstants.protectorId())) revert ProtectorAlreadySetByYou();
      _addActor(actor, role_);
    }
  }

  function _isPluginAuthorizable(bytes4 nameId_, bytes4 salt) internal view virtual {
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (!_pluginByKey[_key].trusted)
      if (!_vault().allowUntrustedTransfers()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    CrunaPluginBase plugin_ = _plugin(nameId_, salt);
    if (!plugin_.requiresToManageTransfer()) revert NotATransferPlugin();
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
        ManagerConstants.gasToEmitLockedEvent(),
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

  function _getKeyAndSalt(bytes4 pluginNameId) internal view returns (bytes8, bytes4) {
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement memory plugin_ = _allPlugins[i];
      bytes4 nameId_ = plugin_.nameId;
      if (nameId_ == pluginNameId) {
        bytes8 key_ = _combineBytes4(nameId_, plugin_.salt);
        if (_pluginAddress(pluginNameId, plugin_.salt) == _msgSender()) {
          return (key_, plugin_.salt);
        }
      }
      unchecked {
        ++i;
      }
    }
    return (bytes8(0), bytes4(0));
  }

  function _pluginIndex(bytes4 nameId_, bytes4 salt) internal view virtual returns (bool, uint256) {
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      if (nameId_ == _allPlugins[i].nameId)
        if (_allPlugins[i].salt == salt) {
          return (true, i);
        }
      unchecked {
        ++i;
      }
    }
    return (false, 0);
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

  function _resetPlugin(bytes4 nameId_, bytes4 salt) internal virtual {
    CrunaPluginBase plugin_ = _plugin(nameId_, salt);
    plugin_.reset();
  }

  function _resetPluginOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual {
    address plugin_ = _pluginAddress(nameId_, salt);
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = plugin_.excessivelySafeCall(
      ManagerConstants.gasToResetPlugin(),
      0,
      32,
      abi.encodeWithSignature("resetOnTransfer()")
    );
    if (!success) {
      emit PluginResetAttemptFailed(nameId_, salt);
    }
  }

  function _removeLockIfExpired(bytes4 nameId_, bytes4 salt) internal virtual {
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].timeLock < block.timestamp) {
      delete _pluginByKey[_key].timeLock;
      _pluginByKey[_key].canManageTransfer = true;
    }
  }

  function _resetOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual {
    _deleteActors(ManagerConstants.protectorId());
    _deleteActors(ManagerConstants.safeRecipientId());
    // disable all plugins
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement memory plugin_ = _allPlugins[i];
      bytes4 _nameId_ = plugin_.nameId;
      if (_nameId_ != nameId_ || plugin_.salt != salt) {
        if (_pluginByKey[_combineBytes4(_nameId_, plugin_.salt)].canBeReset) _resetPluginOnTransfer(_nameId_, plugin_.salt);
      }
      unchecked {
        ++i;
      }
    }
    emit Reset();
  }

  // @dev This empty reserved space is put in place to allow future versions to add new
  // variables without shifting down storage in the inheritance chain.
  // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps

  uint256[50] private __gap;
}
