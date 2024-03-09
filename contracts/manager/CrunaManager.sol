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
  mapping(bytes8 => CrunaPlugin) private _pluginsById;
  mapping(bytes8 => uint256) private _timeLocks;

  error IndexOutOfBounds();

  function pluginsById(bytes8 key) external view returns (CrunaPlugin memory) {
    return _pluginsById[key];
  }

  function allPlugins(uint256 index) external view returns (PluginElement memory) {
    if (index >= _allPlugins.length) revert IndexOutOfBounds();
    return _allPlugins[index];
  }

  function timeLocks(bytes8 key) external view returns (uint256) {
    return _timeLocks[key];
  }

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
    return _actors[ManagerConstants.protectorId()].length > 0;
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
    if (otherTokenId == tokenId()) revert CannotimportProtectorsAndSafeRecipientsFromYourself();
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
        i++;
      }
    }
    address[] memory otherSafeRecipients = otherManager.getSafeRecipients();
    len = otherSafeRecipients.length;
    for (uint256 i; i < len; ) {
      _addActor(otherSafeRecipients[i], ManagerConstants.safeRecipientId());
      unchecked {
        i++;
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
    if (_pluginsById[_combineBytes4(nameId_, salt)].proxyAddress != address(0)) revert PluginAlreadyPlugged();
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
    // If the plugin has been plugged before and later unplugged, the proxy won't be deployed again
    // but the existing address will be returned by the registry.
    address pluginAddress_ = _vault().deployPlugin(proxyAddress_, salt, tokenId(), isERC6551Account);
    CrunaPluginBase plugin_ = CrunaPluginBase(payable(pluginAddress_));
    if (plugin_.nameId() != nameId_) revert InvalidImplementation();
    if (plugin_.isERC6551Account() != isERC6551Account) revert InvalidAccountStatus();
    plugin_.init();
    _allPlugins.push(PluginElement({name: name, active: true, salt: salt}));
    _pluginsById[_combineBytes4(nameId_, salt)] = CrunaPlugin({
      proxyAddress: proxyAddress_,
      canManageTransfer: canManageTransfer,
      canBeReset: plugin_.requiresResetOnTransfer(),
      active: true,
      trusted: requires != 0,
      isERC6551Account: isERC6551Account,
      salt: salt
    });
    emit PluginStatusChange(name, salt, address(plugin_), PluginStatus.PluggedAndActive);
  }

  function unplug(
    string memory name,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    _preValidateAndCheckSignature(
      this.unplug.selector,
      _pseudoAddress(name, salt),
      0,
      // in v2 we will user extra3 for the salt, like:
      // uint256(bytes32(salt)),
      // For now, since the salt is defaulted to salt, we can ignore it.
      0,
      timestamp,
      validFor,
      signature
    );
    uint256 len = _allPlugins.length;
    address pluginAddress_ = _pluginAddress(nameId_, salt);
    for (uint256 i; i < len; ) {
      unchecked {
        if (_hashString(_allPlugins[i].name) == _hashString(name)) {
          if (_pluginsById[_key].canBeReset) {
            _resetPlugin(nameId_, salt);
          }
          _allPlugins[i] = _allPlugins[_allPlugins.length - 1];
          _allPlugins.pop();
          break;
        }
        i++;
      }
    }
    delete _pluginsById[_key];
    emit PluginStatusChange(name, salt, pluginAddress_, PluginStatus.Unplugged);
  }

  // To set as trusted a plugin that initially was not trusted
  // No need for extra protection because the CrunaGuardian absolves that role
  function trustPlugin(string memory name, bytes4 salt) external virtual override onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (_pluginsById[_key].trusted) revert PluginAlreadyTrusted();
    if (Canonical.crunaGuardian().trustedImplementation(nameId_, _pluginsById[_key].proxyAddress) != 0) {
      _pluginsById[_key].trusted = true;
      emit PluginTrusted(name, salt);
    } else revert StillUntrusted();
  }

  // @dev Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
  // the NFT. If the plugins must be blocked for more time, disable it at your peril of making it useless.
  function authorizePluginToTransfer(
    string memory name,
    bytes4 salt,
    bool authorized,
    uint256 timeLock,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    _isPluginAuthorizable(nameId_, salt);
    _preValidateAndCheckSignature(
      this.authorizePluginToTransfer.selector,
      _pseudoAddress(name, salt),
      authorized ? 1 : 0,
      timeLock,
      timestamp,
      validFor,
      signature
    );
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (authorized) {
      if (timeLock != 0) revert InvalidTimeLock();
      if (_pluginsById[_key].canManageTransfer) revert PluginAlreadyAuthorized();
      delete _timeLocks[_key];
    } else {
      if (timeLock == 0 || timeLock > 30 days) revert InvalidTimeLock();
      if (!_pluginsById[_key].canManageTransfer) revert PluginAlreadyUnauthorized();
      _timeLocks[_key] = block.timestamp + timeLock;
    }
    _pluginsById[_key].canManageTransfer = authorized;
    emit PluginAuthorizationChange(name, salt, _pluginAddress(nameId_, salt), authorized, timeLock);
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
    return _pluginsById[_combineBytes4(nameId_, salt)].proxyAddress != address(0);
  }

  function pluginIndex(string memory name, bytes4 salt) external view virtual returns (bool, uint256) {
    return _pluginIndex(name, salt);
  }

  function isPluginActive(string memory name, bytes4 salt) external view virtual returns (bool) {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    return _pluginsById[_key].active;
  }

  function listPlugins(bool active) external view virtual returns (string[] memory) {
    (uint256 actives, uint256 disabled) = _countPlugins();
    string[] memory _plugins = new string[](active ? actives : disabled);
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      if (_allPlugins[i].active == active) {
        _plugins[i] = _allPlugins[i].name;
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
  function pseudoAddress(string memory name, bytes4 _salt) external view virtual returns (address) {
    return _pseudoAddress(name, _salt);
  }

  function disablePlugin(
    string memory name,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    uint256 i = _isPluginEnabled(name, salt);
    _preValidateAndCheckSignature(
      this.disablePlugin.selector,
      _pseudoAddress(name, salt),
      0,
      0,
      timestamp,
      validFor,
      signature
    );
    delete _allPlugins[i].active;
    bytes4 nameId_ = _stringToBytes4(name);
    delete _pluginsById[_combineBytes4(nameId_, salt)].active;
    emit PluginStatusChange(name, salt, _pluginAddress(nameId_, salt), PluginStatus.PluggedAndInactive);
  }

  function reEnablePlugin(
    string memory name,
    bytes4 salt,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    uint256 i = _isPluginDisabled(name, salt);
    _preValidateAndCheckSignature(
      this.reEnablePlugin.selector,
      _pseudoAddress(name, salt),
      0,
      0,
      timestamp,
      validFor,
      signature
    );
    _allPlugins[i].active = true;
    bytes4 nameId_ = _stringToBytes4(name);
    _pluginsById[_combineBytes4(nameId_, salt)].active = true;
    emit PluginStatusChange(name, salt, _pluginAddress(nameId_, salt), PluginStatus.PluggedAndActive);
  }

  // @dev See {IProtected721-managedTransfer}.
  // This is a special function that can be called only by authorized plugins
  function managedTransfer(bytes4 pluginNameId, address to) external virtual override nonReentrant {
    // find the plugin
    bytes8 _key;
    uint256 len = _allPlugins.length;
    bytes4 salt;
    for (uint256 i; i < len; ) {
      bytes4 nameId_ = _stringToBytes4(_allPlugins[i].name);
      if (nameId_ == pluginNameId) {
        bytes8 key_ = _combineBytes4(nameId_, _allPlugins[i].salt);
        if (_pluginAddress(pluginNameId, _allPlugins[i].salt) == _msgSender()) {
          salt = _allPlugins[i].salt;
          _key = key_;
          break;
        }
      }
      unchecked {
        i++;
      }
    }
    if (_key == bytes8(0) || !_pluginsById[_key].active) revert PluginNotFoundOrDisabled();
    if (_pluginAddress(pluginNameId, salt) != _msgSender()) revert NotTheAuthorizedPlugin();
    _removeLockIfExpired(pluginNameId, salt);
    if (!_pluginsById[_key].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
    if (!_pluginsById[_key].trusted)
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
          _pluginsById[_combineBytes4(nameId_, salt)].proxyAddress,
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
        i++;
      }
    }
    return (active, disabled);
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
    if (_pluginsById[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (!_pluginsById[_key].trusted)
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

  function _pluginIndex(string memory name, bytes4 salt) internal view virtual returns (bool, uint256) {
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      if (_hashString(name) == _hashString(_allPlugins[i].name))
        if (_allPlugins[i].salt == salt) {
          return (true, i);
        }
      unchecked {
        i++;
      }
    }
    return (false, 0);
  }

  function _isPluginEnabled(string memory name, bytes4 salt) internal view virtual returns (uint256) {
    (bool plugged_, uint256 i) = _pluginIndex(name, salt);
    if (!plugged_) revert PluginNotFound();
    if (!_allPlugins[i].active) revert PluginAlreadyDisabled();
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
    (bool plugged_, uint256 i) = _pluginIndex(name, salt);
    if (!plugged_) revert PluginNotFound();
    if (_allPlugins[i].active) revert PluginNotDisabled();
    return i;
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
    // Optionally log success/failure
    emit PluginResetAttempt(nameId_, salt, success);
  }

  function _removeLockIfExpired(bytes4 nameId_, bytes4 salt) internal virtual {
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_timeLocks[_key] < block.timestamp) {
      delete _timeLocks[_key];
      _pluginsById[_key].canManageTransfer = true;
    }
  }

  function _resetOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual {
    _deleteActors(ManagerConstants.protectorId());
    _deleteActors(ManagerConstants.safeRecipientId());
    // disable all plugins
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      bytes4 _nameId_ = _stringToBytes4(_allPlugins[i].name);
      if (_nameId_ != nameId_ || _allPlugins[i].salt != salt) {
        if (_pluginsById[_combineBytes4(_nameId_, _allPlugins[i].salt)].canBeReset)
          _resetPluginOnTransfer(_nameId_, _allPlugins[i].salt);
      }
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
