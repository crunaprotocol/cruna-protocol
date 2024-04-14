// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Actor} from "./Actor.sol";
import {CrunaManagerBase} from "./CrunaManagerBase.sol";
import {ExcessivelySafeCall} from "../libs/ExcessivelySafeCall.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CrunaManagedService} from "../services/CrunaManagedService.sol";
import {Canonical} from "../libs/Canonical.sol";
import {TrustedLib} from "../libs/TrustedLib.sol";
import {ManagerConstants} from "../libs/ManagerConstants.sol";
import {Deployed} from "../utils/Deployed.sol";

//import "hardhat/console.sol";

/**
 * @title CrunaManager
 * @notice The manager of the Cruna NFT
 * It is the only contract that can manage the NFT. It sets protectors and safe recipients,
 * plugs and manages services, and has the ability to transfer the NFT if there are protectors.
 */
contract CrunaManager is Actor, CrunaManagerBase, Deployed {
  using ECDSA for bytes32;
  using Strings for uint256;
  using ExcessivelySafeCall for address;

  /**
   * @notice The array of all plugged services. The max length is set to 16 to avoid gas issues.
   */
  PluginElement[] private _allPlugins;

  /**
   * @notice The mapping of all services by key. A key is the combination of the nameId and the salt.
   */
  mapping(bytes8 pluginKey => PluginConfig pluginDetails) private _pluginByKey;

  /// @dev see {IVersioned-version}
  function version() external pure virtual override returns (uint256) {
    return 1_001_000;
  }

  /// @dev see {ICrunaManager-pluginByKey}
  function pluginByKey(bytes8 key) external view returns (PluginConfig memory) {
    return _pluginByKey[key];
  }

  /// @dev see {ICrunaManager-allPlugins}
  function allPlugins() external view returns (PluginElement[] memory) {
    return _allPlugins;
  }

  /// @dev see {ICrunaManager-pluginByIndex}
  function pluginByIndex(uint256 index) external view returns (PluginElement memory) {
    if (index >= _allPlugins.length) revert IndexOutOfBounds();
    return _allPlugins[index];
  }

  /// @dev see {ICrunaManager-migrate}
  function migrate(uint256 /* version */) external virtual override {
    if (_msgSender() != address(this)) revert Forbidden();
    // Nothing, for now, since this is the first version of the manager
  }

  /// @dev see {ICrunaManager-findProtectorIndex}
  function findProtectorIndex(address protector_) external view virtual override returns (uint256) {
    return _actorIndex(protector_, ManagerConstants.protectorId());
  }

  /// @dev see {ICrunaManager-isProtector}
  function isProtector(address protector_) external view virtual override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  /// @dev see {ICrunaManager-hasProtectors}
  function hasProtectors() external view virtual override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  /// @dev see {ICrunaManager-isTransferable}
  function isTransferable(address to) external view override returns (bool) {
    return
      _actors[ManagerConstants.protectorId()].length == 0 ||
      _actorIndex(to, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  /// @dev see {ICrunaManager-locked}
  function locked() external view override returns (bool) {
    return _actors[ManagerConstants.protectorId()].length != 0;
  }

  /// @dev see {ICrunaManager-countProtectors}
  function countProtectors() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.protectorId());
  }

  /// @dev see {ICrunaManager-countSafeRecipients}
  function countSafeRecipients() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.safeRecipientId());
  }

  /// @dev see {ICrunaManager-setProtector}
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
      timestamp,
      validFor,
      signature,
      _msgSender()
    );
    emit ProtectorChange(protector_, status);
    _emitLockeEvent(_actors[ManagerConstants.protectorId()].length, status);
  }

  /// @dev see {ICrunaManager-importProtectorsAndSafeRecipientsFrom}
  function importProtectorsAndSafeRecipientsFrom(uint256 otherTokenId) external virtual override onlyTokenOwner {
    if (_actorCount(ManagerConstants.protectorId()) != 0) revert ProtectorsAlreadySet();
    if (_actorCount(ManagerConstants.safeRecipientId()) != 0) revert SafeRecipientsAlreadySet();
    if (otherTokenId == tokenId()) revert CannotImportProtectorsAndSafeRecipientsFromYourself();
    if (_vault().ownerOf(otherTokenId) != owner()) revert NotTheSameOwner(_vault().ownerOf(otherTokenId), owner());
    CrunaManager otherManager = CrunaManager(_vault().managerOf(otherTokenId));
    if (otherManager.countProtectors() == 0)
      if (otherManager.countSafeRecipients() == 0) revert NothingToImport();
    address[] memory otherProtectors = otherManager.getProtectors();
    uint256 len = otherProtectors.length;
    for (uint256 i; i < len; ) {
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

  /// @dev see {ICrunaManager-getProtectors}
  function getProtectors() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.protectorId());
  }

  /// @dev see {ICrunaManager-setSafeRecipient}
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

  /// @dev see {ICrunaManager-isSafeRecipient}
  function isSafeRecipient(address recipient) external view virtual override returns (bool) {
    return _actorIndex(recipient, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  /// @dev see {ICrunaManager-getSafeRecipients}
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.safeRecipientId());
  }

  /**
   *
   * PLUGINS
   *
   */

  /// @dev see {ICrunaManager-plug}
  function plug(
    string memory name,
    address pluginProxy,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4 salt,
    bytes memory data,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    if (_allPlugins.length == 16) {
      // We do not allow more than 16 services to avoid risks of going out-of-gas while
      // looping through allPlugins.
      revert PluginNumberOverflow();
    }
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress != address(0) && !_pluginByKey[_key].unplugged) revert PluginAlreadyPlugged();
    bool trusted = Canonical.crunaGuardian().trustedImplementation(nameId_, pluginProxy);
    if (!trusted)
      if (canManageTransfer)
        if (!TrustedLib.areUntrustedImplementationsAllowed()) {
          revert UntrustedImplementationsNotAllowedToMakeTransfers();
        }
    _preValidateAndCheckSignature(
      this.plug.selector,
      pluginProxy,
      canManageTransfer ? 1 : 0,
      isERC6551Account ? 1 : 0,
      uint256(bytes32(salt)),
      timestamp,
      validFor,
      signature
    );
    if (_pluginByKey[_key].banned) revert PluginHasBeenMarkedAsNotPluggable();
    _plug(name, pluginProxy, canManageTransfer, isERC6551Account, nameId_, salt, data, _key, trusted);
  }

  /// @dev see {ICrunaManager-changePluginStatus}
  function changePluginStatus(
    string calldata name,
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
      0,
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

  /// @dev see {ICrunaManager-trustPlugin}
  function trustPlugin(string calldata name, bytes4 salt) external virtual override onlyTokenOwner {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress == address(0)) revert PluginNotFound();
    if (_pluginByKey[_key].trusted) revert PluginAlreadyTrusted();
    if (Canonical.crunaGuardian().trustedImplementation(nameId_, _pluginByKey[_key].proxyAddress)) {
      _pluginByKey[_key].trusted = true;
      emit PluginTrusted(name, salt);
    } else revert StillUntrusted();
  }

  /// @dev see {ICrunaManager-pluginAddress}
  function pluginAddress(bytes4 nameId_, bytes4 salt) external view virtual override returns (address payable) {
    return _pluginAddress(nameId_, salt);
  }

  /// @dev see {ICrunaManager-plugin}
  function plugin(bytes4 nameId_, bytes4 salt) external view virtual override returns (CrunaManagedService) {
    return _plugin(nameId_, salt);
  }

  /// @dev see {ICrunaManager-countPlugins}
  function countPlugins() external view virtual override returns (uint256, uint256) {
    return _countPlugins();
  }

  /// @dev see {ICrunaManager-plugged}
  function plugged(string calldata name, bytes4 salt) external view virtual returns (bool) {
    bytes4 nameId_ = _stringToBytes4(name);
    return
      _pluginByKey[_combineBytes4(nameId_, salt)].proxyAddress != address(0) &&
      !_pluginByKey[_combineBytes4(nameId_, salt)].unplugged;
  }

  /// @dev see {ICrunaManager-pluginIndex}
  function pluginIndex(string calldata name, bytes4 salt) external view virtual returns (bool, uint256) {
    return _pluginIndex(_stringToBytes4(name), salt);
  }

  /// @dev see {ICrunaManager-isPluginActive}
  function isPluginActive(string calldata name, bytes4 salt) external view virtual returns (bool) {
    bytes4 nameId_ = _stringToBytes4(name);
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].proxyAddress == address(0)) revert PluginNotFound();
    return _pluginByKey[_key].active;
  }

  /// @dev see {ICrunaManager-listPluginsKeys}
  function listPluginsKeys(bool active) external view virtual returns (bytes8[] memory) {
    (uint256 actives, uint256 disabled) = _countPlugins();
    bytes8[] memory _keys = new bytes8[](active ? actives : disabled);
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement storage plugin_ = _allPlugins[i];
      if (plugin_.active == active) {
        _keys[i] = _combineBytes4(plugin_.nameId, plugin_.salt);
      }
      unchecked {
        ++i;
      }
    }
    return _keys;
  }

  /// @dev see {ICrunaManager-pseudoAddress}
  function pseudoAddress(string calldata name, bytes4 _salt) external view virtual returns (address) {
    return _pseudoAddress(name, _salt);
  }

  /**
   * @notice see {IProtectedNFT-managedTransfer}.
   */
  function managedTransfer(bytes4 pluginNameId, address to) external virtual override nonReentrant {
    (bytes8 _key, bytes4 salt) = _getKeyAndSalt(pluginNameId);
    if (_key == bytes8(0) || !_pluginByKey[_key].active) revert PluginNotFoundOrDisabled();
    if (_pluginAddress(pluginNameId, salt) != _msgSender()) revert NotTheAuthorizedPlugin(_msgSender());
    _removeLockIfExpired(pluginNameId, salt);
    if (!_pluginByKey[_key].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
    if (!_pluginByKey[_key].trusted)
      if (!TrustedLib.areUntrustedImplementationsAllowed()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    _resetOnTransfer(pluginNameId, salt);
    // In theory, the vault may revert, blocking the entire process
    // We allow it, assuming that the vault implementation has the
    // right to set up more advanced rules, before allowing the transfer,
    // despite the plugin has the ability to do so.
    _vault().managedTransfer(pluginNameId, tokenId(), to);
  }

  /**
   * @notice see {IProtectedNFT-protectedTransfer}.
   */
  function protectedTransfer(
    uint256 tokenId_,
    address to,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external override onlyTokenOwner {
    if (timestamp == 0) revert ToBeUsedOnlyWhenProtectorsAreActive();
    _preValidateAndCheckSignature(this.protectedTransfer.selector, to, 0, 0, 0, timestamp, validFor, signature);
    _resetOnTransfer(bytes4(0), bytes4(0));
    _vault().managedTransfer(_nameId(), tokenId_, to);
  }

  // Internal function to get an instance of the plugin
  function _plugin(bytes4 nameId_, bytes4 salt) internal view virtual returns (CrunaManagedService) {
    return CrunaManagedService(_pluginAddress(nameId_, salt));
  }

  /**
   * @notice returns the address of a deployed plugin
   * @param nameId_ The nameId of the plugin
   * @param salt The salt of the plugin
   */
  function _pluginAddress(bytes4 nameId_, bytes4 salt) internal view virtual returns (address payable) {
    PluginConfig storage config_ = _pluginByKey[_combineBytes4(nameId_, salt)];
    return payable(_addressOfDeployed(config_.proxyAddress, salt, tokenAddress(), tokenId(), config_.isERC6551Account));
  }

  /**
   * @notice returns the name Id of the manager
   */
  function _nameId() internal view virtual override returns (bytes4) {
    return bytes4(keccak256("CrunaManager"));
  }

  /**
   * @notice returns a pseudoaddress composed by the name of the plugin and the salt used
   * to deploy it. This is needed to pass a valid address as an actor to the SignatureValidator
   * @param name The name of the plugin
   * @param _salt The salt used to deploy the plugin
   * @return The pseudoaddress
   */
  function _pseudoAddress(string calldata name, bytes4 _salt) internal view virtual returns (address) {
    return address(uint160(uint256(keccak256(abi.encodePacked(name, _salt)))));
  }

  /**
   * @notice Counts the active and disabled services
   */
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

  /**
   * @notice Internal function to disable a plugin but index and key
   * @param i The index of the plugin in the _allPlugins array
   * @param _key The key of the plugin
   */
  function _disablePlugin(uint256 i, bytes8 _key) internal {
    if (!_allPlugins[i].active) revert PluginAlreadyDisabled();
    delete _allPlugins[i].active;
    delete _pluginByKey[_key].active;
  }

  /**
   * @notice Internal function to re-enable a plugin but index and key
   * @param i The index of the plugin in the _allPlugins array
   * @param _key The key of the plugin
   */
  function _reEnablePlugin(uint256 i, bytes8 _key) internal {
    if (_allPlugins[i].active) revert PluginNotDisabled();
    _allPlugins[i].active = true;
    _pluginByKey[_key].active = true;
  }

  /**
   * @notice Unplugs a plugin
   * @param i The index of the plugin in the _allPlugins array
   * @param nameId_ The nameId of the plugin
   * @param salt The salt used to deploy the plugin
   * @param _key The key of the plugin
   * @param change The change to be made (Unplug or UnplugForever)
   */
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

  /**
   * @notice Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
   * the NFT. If the services must be blocked for more time, disable it at your peril of making it useless.
   */
  function _authorizePluginToTransfer(
    bytes4 nameId_,
    bytes4 salt,
    bytes8 _key,
    PluginChange change,
    uint256 timeLock
  ) internal virtual {
    if (!_pluginByKey[_key].trusted)
      if (!TrustedLib.areUntrustedImplementationsAllowed()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    CrunaManagedService plugin_ = _plugin(nameId_, salt);
    if (!plugin_.requiresToManageTransfer()) revert NotATransferPlugin();
    if (change == PluginChange.Authorize) {
      if (timeLock != 0) revert InvalidTimeLock(timeLock);
      if (_pluginByKey[_key].canManageTransfer) revert PluginAlreadyAuthorized();
      delete _pluginByKey[_key].timeLock;
      _pluginByKey[_key].canManageTransfer = true;
    } else {
      // more gas efficient than using an || operator
      if (timeLock == 0) revert InvalidTimeLock(timeLock);
      if (timeLock > 30 days) revert InvalidTimeLock(timeLock);
      if (!_pluginByKey[_key].canManageTransfer) revert PluginAlreadyUnauthorized();
      _pluginByKey[_key].timeLock = uint32(block.timestamp + timeLock);
      delete _pluginByKey[_key].canManageTransfer;
    }
  }

  /**
   * @notice Utility function to combine two bytes4 into a bytes8
   */
  function _combineBytes4(bytes4 a, bytes4 b) internal pure returns (bytes8) {
    return bytes8(bytes32(a) | (bytes32(b) >> 32));
  }

  /**
   * @notice Check if the NFT is protected
   */
  function _isProtected() internal view virtual override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  /**
   * @notice Checks if an address is a protector
   * @param protector_ The address to check
   */
  function _isProtector(address protector_) internal view virtual override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  /**
   * @notice Override required by SignatureValidator to check if a signer is authorized to pre-approve an operation
   * @param selector The selector of the called function
   * @param actor The actor to be approved
   * @param signer The signer of the operation (the protector)
   */
  function _canPreApprove(bytes4 selector, address actor, address signer) internal view virtual override returns (bool) {
    if (_actors[ManagerConstants.protectorId()].length == 0) {
      // if there are no protectors, the signer can pre-approve its own candidate
      return selector == this.setProtector.selector && actor == signer;
    }
    return _isActiveActor(signer, ManagerConstants.protectorId());
  }

  /**
   * @notice Internal function plug a plugin
   * @param name The name of the plugin
   * @param proxyAddress_ The address of the plugin
   * @param canManageTransfer If the plugin can manage the transfer of the NFT
   * @param isERC6551Account If the plugin is an ERC6551 account
   * @param nameId_ The nameId of the plugin
   * @param salt The salt used to deploy the plugin
   * @param _key The key of the plugin
   */
  function _plug(
    string memory name,
    address proxyAddress_,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes4 nameId_,
    bytes4 salt,
    bytes memory data,
    bytes8 _key,
    bool trusted
  ) internal {
    // If the plugin has been plugged before and later unplugged, the proxy won't be deployed again.
    address pluginAddress_ = _deploy(proxyAddress_, salt, tokenAddress(), tokenId(), isERC6551Account);
    CrunaManagedService plugin_ = CrunaManagedService(payable(pluginAddress_));
    if (!plugin_.isManaged()) revert UnmanagedService();
    uint256 requiredVersion = plugin_.requiresManagerVersion();
    if (requiredVersion > _version()) revert PluginRequiresUpdatedManager(requiredVersion);
    if (plugin_.nameId() != nameId_) revert InvalidImplementation(plugin_.nameId(), nameId_);
    if (plugin_.isERC6551Account() != isERC6551Account) revert InvalidERC6551Status();
    plugin_.init(data);
    _allPlugins.push(PluginElement({active: true, salt: salt, nameId: nameId_}));
    if (_pluginByKey[_key].unplugged) {
      if (_pluginByKey[_key].proxyAddress != proxyAddress_)
        revert InconsistentProxyAddresses(_pluginByKey[_key].proxyAddress, proxyAddress_);
    }
    _pluginByKey[_key] = PluginConfig({
      proxyAddress: proxyAddress_,
      salt: salt,
      timeLock: 0,
      canManageTransfer: canManageTransfer,
      canBeReset: plugin_.requiresResetOnTransfer(),
      active: true,
      isERC6551Account: isERC6551Account,
      trusted: trusted,
      banned: false,
      unplugged: false
    });
    emit PluginStatusChange(name, salt, pluginAddress_, uint256(PluginChange.Plug));
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
    _preValidateAndCheckSignature(_functionSelector, actor, status ? 1 : 0, 0, 0, timestamp, validFor, signature);
    if (status) {
      if (timestamp != 0)
        if (_functionSelector == this.setProtector.selector)
          if (_isActiveActor(actor, ManagerConstants.protectorId())) revert ProtectorAlreadySetByYou(actor);
      _addActor(actor, role_);
    } else {
      if (timestamp != 0)
        if (_functionSelector == this.setProtector.selector)
          if (!_isActiveActor(actor, ManagerConstants.protectorId()))
            // setProtector
            revert ProtectorNotFound(actor);
      _removeActor(actor, role_);
    }
  }

  /**
   * @notice It asks the NFT to emit a Locked event, according to IERC6982
   * @param protectorsCount The number of protectors
   * @param status If latest protector has been added or removed
   */
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

  /**
   * @notice It returns the key and the salt of the current plugin calling the manager
   * @param pluginNameId The nameId of the plugin
   */
  function _getKeyAndSalt(bytes4 pluginNameId) internal view returns (bytes8, bytes4) {
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement storage plugin_ = _allPlugins[i];
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

  /**
   * @notice It returns the index of the plugin in the _allPlugins array
   */
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

  /**
   * @notice Util to validate and check the signature
   * @param selector The selector of the function
   * @param actor The address of the actor (if a protector/safe recipient) or the pseudoAddress of a plugin
   * @param extra An extra value to be signed
   * @param extra2 An extra value to be signed
   * @param extra3 An extra value to be signed
   * @param timestamp The timestamp of the request
   * @param validFor The validity of the request
   * @param signature The signature of the request
   */
  function _preValidateAndCheckSignature(
    bytes4 selector,
    address actor,
    uint256 extra,
    uint256 extra2,
    uint256 extra3,
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
      extra3,
      timestamp * _TIMESTAMP_MULTIPLIER + validFor,
      signature
    );
  }

  /**
   * @notice It resets a plugin
   * @param nameId_ The nameId of the plugin
   * @param salt The salt of the plugin
   */
  function _resetPlugin(bytes4 nameId_, bytes4 salt) internal virtual {
    CrunaManagedService plugin_ = _plugin(nameId_, salt);
    plugin_.reset();
  }

  /**
   * @notice It resets a plugin on transfer.
   * It tries to minimize risks and gas consumption limiting the amount of gas sent to
   * the plugin. Since the called function should not be overridden, it should be safe.
   * @param nameId_ The nameId of the plugin
   * @param salt The salt of the plugin
   */
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
      // This should never happen. But it can happen if the user replace CrunaManagedService
      // with its own implementation — not advised to do :-(
      emit PluginResetAttemptFailed(nameId_, salt);
    }
  }

  /**
   * @notice If a plugin has been temporarily deAuthorized from transferring the tolen, it
   * removes the lock if the lock is expired
   * @param nameId_ The nameId of the plugin
   * @param salt The salt of the plugin
   */
  function _removeLockIfExpired(bytes4 nameId_, bytes4 salt) internal virtual {
    bytes8 _key = _combineBytes4(nameId_, salt);
    if (_pluginByKey[_key].timeLock < block.timestamp) {
      delete _pluginByKey[_key].timeLock;
      _pluginByKey[_key].canManageTransfer = true;
    }
  }

  /**
   * @notice It resets the manager on transfer
   * @param nameId_ The nameId of the plugin calling the transfer
   * @param salt The salt of the plugin calling the transfer
   */
  function _resetOnTransfer(bytes4 nameId_, bytes4 salt) internal virtual {
    _deleteActors(ManagerConstants.protectorId());
    _deleteActors(ManagerConstants.safeRecipientId());
    // disable all services
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      PluginElement storage plugin_ = _allPlugins[i];
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
