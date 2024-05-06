// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.20;

// Author: Francesco Sullo <francesco@sullo.co>

import {Actor} from "./Actor.sol";
import {ManagerConstants, CrunaManagerBase} from "./CrunaManagerBase.sol";
import {ExcessivelySafeCall} from "../libs/ExcessivelySafeCall.sol";

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {CrunaManagedService} from "../services/CrunaManagedService.sol";
import {GuardianInstance} from "../libs/GuardianInstance.sol";
import {TrustedLib} from "../libs/TrustedLib.sol";
import {Deployer} from "../utils/Deployer.sol";

//import "hardhat/console.sol";

/**
 * @title CrunaManager
 * @notice The manager of the Cruna NFT
 * It is the only contract that can manage the NFT. It sets protectors and safe recipients,
 * plugs and manages services, and has the ability to transfer the NFT if there are protectors.
 */
contract CrunaManager is GuardianInstance, Actor, CrunaManagerBase, Deployer {
  using ECDSA for bytes32;
  using Strings for uint256;
  using ExcessivelySafeCall for address;

  /**
   * @notice The array of all plugged services. The max length is set to 16 to avoid gas issues.
   */
  bytes32[] private _allPlugins;

  /**
   * @notice The mapping of all services by key. A key is the combination of the nameId and the salt.
   */
  mapping(bytes32 _pluginKey => PluginConfig pluginDetails) private _pluginByKey;

  /**
   * @notice Returns the version of the contract.
   * The format is similar to semver, where any element takes 3 digits.
   * For example, version 1.2.14 is 1_002_014.
   */
  function version() external pure virtual override returns (uint256) {
    return 1_001_000;
  }

  /**
   * @dev It returns the configuration of a plugin by key
   * @param key The key of the plugin
   */
  function pluginByKey(bytes32 key) external view returns (PluginConfig memory) {
    return _pluginByKey[key];
  }

  /**
   * @dev It returns the configuration of all currently plugged services
   */
  function allPlugins() external view returns (bytes32[] memory) {
    return _allPlugins;
  }

  /**
   * @dev It returns an element of the array of all plugged services
   * @param index The index of the plugin in the array
   */
  function pluginByIndex(uint256 index) external view returns (bytes32) {
    if (index >= _allPlugins.length) revert IndexOutOfBounds();
    return _allPlugins[index];
  }

  /**
   * @dev During an upgrade allows the manager to perform adjustments if necessary.
   * The parameter is the version of the manager being replaced. This will allow the
   * new manager to know what to do to adjust the state of the new manager.
   */
  function migrate(uint256 /* version */) external virtual override {
    if (_msgSender() != address(this)) revert Forbidden();
    // Nothing, for now, since this is the first version of the manager
  }

  /**
   * @dev Find a specific protector
   */
  function findProtectorIndex(address protector_) external view virtual override returns (uint256) {
    return _actorIndex(protector_, ManagerConstants.protectorId());
  }

  /**
   * @dev Returns true if the address is a protector.
   * @param protector_ The protector address.
   */
  function isProtector(address protector_) external view virtual override returns (bool) {
    return _isActiveActor(protector_, ManagerConstants.protectorId());
  }

  /**
   * @dev Returns true if there are protectors.
   */
  function hasProtectors() external view virtual override returns (bool) {
    return _actorCount(ManagerConstants.protectorId()) != 0;
  }

  /**
   * @dev Returns true if the token is transferable (since the NFT is ERC6454)
   * @param to The address of the recipient.
   * If the recipient is a safe recipient, it returns true.
   */
  function isTransferable(address to) external view override returns (bool) {
    return
      _actors[ManagerConstants.protectorId()].length == 0 ||
      _actorIndex(to, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  /**
   * @dev Returns true if the token is locked (since the NFT is ERC6982)
   */
  function locked() external view override returns (bool) {
    return _actors[ManagerConstants.protectorId()].length != 0;
  }

  /**
   * @dev Counts how many protectors have been set
   */
  function countProtectors() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.protectorId());
  }

  /**
   * @dev Counts the safe recipients
   */
  function countSafeRecipients() external view virtual override returns (uint256) {
    return _actorCount(ManagerConstants.safeRecipientId());
  }

  /**
   * @dev Set a protector for the token
   * @param protector_ The protector address
   * @param status True to add a protector, false to remove it
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   * If no signature is required, the field timestamp must be 0
   * If the operations has been pre-approved by the protector, the signature should be replaced
   * by a shorter (invalid) one, to tell the signature validator to look for a pre-approval.
   */
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

  /**
   * @dev Imports protectors and safe recipients from another tokenId owned by the same owner
   * It requires that there are no protectors and no safe recipients in the current token, and
   * that the origin token has at least one protector or one safe recipient.
   */
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

  /**
   * @dev get the list of all protectors
   */
  function getProtectors() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.protectorId());
  }

  /**
   * @dev Set a safe recipient for the token, i.e., an address that can receive the token without any restriction
   * even when protectors have been set.
   * @param recipient The recipient address
   * @param status True to add a safe recipient, false to remove it
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
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

  /**
   * @dev Check if an address is a safe recipient
   * @param recipient The recipient address
   * @return True if the recipient is a safe recipient
   */
  function isSafeRecipient(address recipient) external view virtual override returns (bool) {
    return _actorIndex(recipient, ManagerConstants.safeRecipientId()) != ManagerConstants.maxActors();
  }

  /**
   * @dev Gets all safe recipients
   * @return An array with the list of all safe recipients
   */
  function getSafeRecipients() external view virtual override returns (address[] memory) {
    return _getActors(ManagerConstants.safeRecipientId());
  }

  /**
   *
   * PLUGINS
   *
   */

  /**
   * @dev It plugs a new plugin
   * @param key_ The key of the plugin
   * @param canManageTransfer True if the plugin can manage transfers
   * @param isERC6551Account True if the plugin is an ERC6551 account
   * @param data The data to be used during the initialization of the plugin
   * Notice that data cannot be verified by the Manager since they are used by the plugin
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
  function plug(
    bytes32 key_,
    bool canManageTransfer,
    bool isERC6551Account,
    bytes memory data,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    if (_allPlugins.length == 16) {
      // We do not allow more than 16 managed services to avoid risks of going out-of-gas while
      // looping through allPlugins.
      revert PluginNumberOverflow();
    }
    if (_pluginByKey[key_].deployed && !_pluginByKey[key_].unplugged) revert PluginAlreadyPlugged();
    bool trusted = _crunaGuardian().trusted(_implFromKey(key_));
    if (!trusted)
      if (canManageTransfer)
        if (!TrustedLib.areUntrustedImplementationsAllowed()) {
          revert UntrustedImplementationsNotAllowedToMakeTransfers();
        }
    _preValidateAndCheckSignature(
      this.plug.selector,
      address(0),
      uint256(key_),
      (canManageTransfer ? 1 : 0) * 1e6 + (isERC6551Account ? 1 : 0),
      uint256(_hashBytes(data)),
      timestamp,
      validFor,
      signature
    );
    if (_pluginByKey[key_].banned) revert PluginHasBeenMarkedAsNotPluggable();
    _plug(key_, canManageTransfer, isERC6551Account, data, trusted);
  }

  /**
   * @dev It changes the status of a plugin
   * @param key_ The key of the plugin
   * @param change The type of change
   * @param timeLock_ The time lock for when a plugin is temporarily unauthorized from making transfers
   * @param timestamp The timestamp of the signature
   * @param validFor The validity of the signature
   * @param signature The signature of the protector
   */
  function changePluginStatus(
    bytes32 key_,
    PluginChange change,
    uint256 timeLock_,
    uint256 timestamp,
    uint256 validFor,
    bytes calldata signature
  ) external virtual override nonReentrant onlyTokenOwner {
    (bool plugged_, uint256 i) = _pluginIndex(key_);
    if (!plugged_) revert PluginNotFound();
    _preValidateAndCheckSignature(
      this.changePluginStatus.selector,
      _pseudoAddress(key_),
      uint256(change),
      timeLock_,
      0,
      timestamp,
      validFor,
      signature
    );
    if (change == PluginChange.Disable) {
      _disablePlugin(i);
    } else if (change == PluginChange.ReEnable) {
      _reEnablePlugin(i);
    } else if (change == PluginChange.Authorize || change == PluginChange.DeAuthorize) {
      emit PluginStatusChange(key_, _pluginAddress(key_), timeLock_ * 1e3 + uint256(change));
      _authorizePluginToTransfer(key_, change, timeLock_);
      return;
    } else if (change == PluginChange.Unplug || change == PluginChange.UnplugForever) {
      emit PluginStatusChange(key_, _pluginAddress(key_), uint256(change));
      _unplugPlugin(i, key_, change);
      return;
    } else if (change == PluginChange.Reset) {
      _resetPlugin(key_);
    } else revert UnsupportedPluginChange();
    emit PluginStatusChange(key_, _pluginAddress(key_), uint256(change));
  }

  /**
   * @dev It trusts a plugin
   * @param key_ The key of the plugin
   * No need for a signature by a protector because the safety of the plugin is
   * guaranteed by the CrunaGuardian.
   */
  function trustPlugin(bytes32 key_) external virtual override onlyTokenOwner {
    if (!_pluginByKey[key_].deployed) revert PluginNotFound();
    if (_pluginByKey[key_].trusted) revert PluginAlreadyTrusted();
    if (_crunaGuardian().trusted(_implFromKey(key_))) {
      _pluginByKey[key_].trusted = true;
      emit PluginTrusted(key_);
    } else revert StillUntrusted(key_);
  }

  /**
   * @dev It returns the address of a plugin
   * @param key_ The key of the plugin
   * The address is returned even if a plugin has not deployed yet.
   * @return The plugin address
   */
  function pluginAddress(bytes32 key_) external view virtual override returns (address payable) {
    return _pluginAddress(key_);
  }

  /**
   * @dev It returns a plugin by name and salt
   * @param key_ The key of the plugin
   * The plugin is returned even if a plugin has not deployed yet, which means that it will
   * revert during the execution.
   * @return The plugin
   */
  function plugin(bytes32 key_) external view virtual override returns (CrunaManagedService) {
    return _plugin(key_);
  }

  /**
   * @dev It returns the number of services
   */
  function countPlugins() external view virtual override returns (uint256, uint256) {
    return _countPlugins();
  }

  /**
   * @dev Says if a plugin is currently plugged
   * @param key_ The key of the plugin
   */
  function plugged(bytes32 key_) external view virtual returns (bool) {
    return _pluginByKey[key_].deployed && !_pluginByKey[key_].unplugged;
  }

  /**
   * @dev Returns the index of a plugin
   * @param key_ The key of the plugin
   * @return a tuple with a true if the plugin is found, and the index of the plugin
   */
  function pluginIndex(bytes32 key_) external view virtual returns (bool, uint256) {
    return _pluginIndex(key_);
  }

  /**
   * @dev Checks if a plugin is active
   * @param key_ The key of the plugin
   * @return True if the plugin is active
   */
  function isPluginActive(bytes32 key_) external view virtual returns (bool) {
    if (!_pluginByKey[key_].deployed) revert PluginNotFound();
    return _pluginByKey[key_].active;
  }

  /**
   * @dev returns the list of services' keys
   * Since the names of the services are not saved in the contract, the app calling for this function
   * is responsible for knowing the names of all the services.
   * In the future it would be good to have an official registry of all services to be able to reverse
   * from the nameId to the name as a string.
   * @param active True to get the list of active services, false to get the list of inactive services
   * @return The list of services' keys
   */
  function listPluginsKeys(bool active) external view virtual returns (bytes32[] memory) {
    (uint256 actives, uint256 disabled) = _countPlugins();
    bytes32[] memory _keys = new bytes32[](active ? actives : disabled);
    uint256 len = _allPlugins.length;
    uint256 j = 0;
    for (uint256 i; i < len; ) {
      if (_pluginByKey[_allPlugins[i]].active == active) {
        _keys[j++] = _allPlugins[i];
      }
      unchecked {
        ++i;
      }
    }
    return _keys;
  }

  function pseudoAddress(bytes32 key_) external view virtual returns (address) {
    return _pseudoAddress(key_);
  }

  /**
   * @notice see {IProtectedNFT-managedTransfer}.
   */
  function managedTransfer(bytes32 key_, address to) external virtual override nonReentrant {
    if (!_pluginByKey[key_].active) revert PluginNotFoundOrDisabled();
    if (_pluginAddress(key_) != _msgSender()) revert NotTheAuthorizedPlugin(_msgSender());
    _removeLockIfExpired(key_);
    if (!_pluginByKey[key_].canManageTransfer) revert PluginNotAuthorizedToManageTransfer();
    if (!_pluginByKey[key_].trusted)
      if (!TrustedLib.areUntrustedImplementationsAllowed()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    _resetOnTransfer(key_);
    // In theory, the vault may revert, blocking the entire process
    // We allow it, assuming that the vault implementation has the
    // right to set up more advanced rules, before allowing the transfer,
    // despite the plugin has the ability to do so.
    _vault().managedTransfer(key_, tokenId(), to);
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
    _resetOnTransfer(bytes32(0));
    _vault().managedTransfer(_nameId(), tokenId_, to);
  }

  // Internal function to get an instance of the plugin
  function _plugin(bytes32 key_) internal view virtual returns (CrunaManagedService) {
    return CrunaManagedService(_pluginAddress(key_));
  }

  /**
   * @notice returns the address of a deployed plugin
   * @param key_ The key of the plugin
   */
  function _pluginAddress(bytes32 key_) internal view virtual returns (address payable) {
    return
      payable(
        _addressOfDeployed(
          _implFromKey(key_),
          _saltFromKey(key_),
          tokenAddress(),
          tokenId(),
          _pluginByKey[key_].isERC6551Account
        )
      );
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
   * @param key_ The key of the plugin
   * @return The pseudoaddress
   */
  function _pseudoAddress(bytes32 key_) internal pure returns (address) {
    address result;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0, key_)
      let hash := keccak256(0, 32)
      result := and(hash, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
    }
    return result;
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
        if (_pluginByKey[_allPlugins[i]].active) active++;
        else disabled++;
        ++i;
      }
    }
    return (active, disabled);
  }

  /**
   * @notice Internal function to disable a plugin but index and key
   * @param i The index of the plugin in the _allPlugins array
   */
  function _disablePlugin(uint256 i) internal {
    if (!_pluginByKey[_allPlugins[i]].active) revert PluginAlreadyDisabled();
    _pluginByKey[_allPlugins[i]].active = false;
  }

  /**
   * @notice Internal function to re-enable a plugin but index and key
   * @param i The index of the plugin in the _allPlugins array
   */
  function _reEnablePlugin(uint256 i) internal {
    if (_pluginByKey[_allPlugins[i]].active) revert PluginNotDisabled();
    _pluginByKey[_allPlugins[i]].active = true;
  }

  /**
   * @notice Unplugs a plugin
   * @param i The index of the plugin in the _allPlugins array
   * @param key_ The key of the plugin
   * @param change The change to be made (Unplug or UnplugForever)
   */
  function _unplugPlugin(uint256 i, bytes32 key_, PluginChange change) internal {
    if (_pluginByKey[key_].canBeReset) {
      if (change == PluginChange.UnplugForever) {
        // The plugin is somehow hostile (for example cause reverts trying to reset it)
        // We mark it as no not pluggable, to avoid re-plugging it in the future.
        // Notice that the same type of plugin can still be plugged using a different salt.
        _pluginByKey[key_].banned = true;
      } else {
        // resets the plugin
        _resetPlugin(key_);
      }
    }
    // _allPlugins.length is > 0 because we are unplugging an existing plugin
    if (i != _allPlugins.length - 1) {
      _allPlugins[i] = _allPlugins[_allPlugins.length - 1];
    }
    _allPlugins.pop();
    _pluginByKey[key_].unplugged = true;
  }

  /**
   * @notice Id removing the authorization, it blocks a plugin for a maximum of 30 days from transferring
   * the NFT. If the services must be blocked for more time, disable it at your peril of making it useless.
   */
  function _authorizePluginToTransfer(bytes32 key_, PluginChange change, uint256 timeLock) internal virtual {
    if (!_pluginByKey[key_].trusted)
      if (!TrustedLib.areUntrustedImplementationsAllowed()) revert UntrustedImplementationsNotAllowedToMakeTransfers();
    CrunaManagedService plugin_ = _plugin(key_);
    if (!plugin_.requiresToManageTransfer()) revert NotATransferPlugin();
    if (change == PluginChange.Authorize) {
      if (timeLock != 0) revert InvalidTimeLock(timeLock);
      if (_pluginByKey[key_].canManageTransfer) revert PluginAlreadyAuthorized();
      delete _pluginByKey[key_].timeLock;
      _pluginByKey[key_].canManageTransfer = true;
    } else {
      // more gas efficient than using an || operator
      if (timeLock == 0) revert InvalidTimeLock(timeLock);
      if (timeLock > 30 days) revert InvalidTimeLock(timeLock);
      if (!_pluginByKey[key_].canManageTransfer) revert PluginAlreadyUnauthorized();
      _pluginByKey[key_].timeLock = uint32(block.timestamp + timeLock);
      delete _pluginByKey[key_].canManageTransfer;
    }
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
   * @param key_ The key of the plugin
   * @param canManageTransfer If the plugin can manage the transfer of the NFT
   * @param isERC6551Account If the plugin is an ERC6551 account
   * @param data Optional data to be passed to the service
   * @param key_ The key of the plugin
   * @param trusted true if the implementation is trusted
   */
  function _plug(bytes32 key_, bool canManageTransfer, bool isERC6551Account, bytes memory data, bool trusted) internal {
    // If the plugin has been plugged before and later unplugged, the proxy won't be deployed again.
    address firstImplementation_ = _implFromKey(key_);
    bytes4 salt = _saltFromKey(key_);
    bytes4 nameId_ = _nameIdFromKey(key_);
    address pluginAddress_ = _deploy(firstImplementation_, salt, tokenAddress(), tokenId(), isERC6551Account);
    CrunaManagedService plugin_ = CrunaManagedService(payable(pluginAddress_));
    if (!plugin_.isManaged()) revert UnmanagedService();
    uint256 requiredVersion = plugin_.requiredManagerVersion();
    if (requiredVersion > _version()) revert PluginRequiresUpdatedManager(requiredVersion);
    if (plugin_.nameId() != nameId_) revert InvalidImplementation(plugin_.nameId(), nameId_);
    if (plugin_.isERC6551Account() != isERC6551Account) revert InvalidERC6551Status();
    /**
     * @dev it is the service responsibility to assure that `init` can be called only one time
     * The rationale for call `init` anytime is that an hostile agent can use the registry to deploy
     * a service that later cannot be initiated if the can be initiated only at the deployment.
     */
    plugin_.init(data);
    _allPlugins.push(key_);
    _pluginByKey[key_] = PluginConfig({
      deployed: true,
      canManageTransfer: canManageTransfer,
      canBeReset: plugin_.requiresResetOnTransfer(),
      active: true,
      isERC6551Account: isERC6551Account,
      trusted: trusted,
      banned: false,
      unplugged: false,
      timeLock: 0
    });
    emit PluginStatusChange(key_, pluginAddress_, uint256(PluginChange.Plug));
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
   * @notice It returns the index of the plugin in the _allPlugins array
   * @param key_ The key of the plugin
   */
  function _pluginIndex(bytes32 key_) internal view virtual returns (bool, uint256) {
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      if (_allPlugins[i] == key_) return (true, i);
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
   * @param key_ The key of the plugin
   */
  function _resetPlugin(bytes32 key_) internal virtual {
    CrunaManagedService plugin_ = _plugin(key_);
    plugin_.resetService();
  }

  /**
   * @notice It resets a plugin on transfer.
   * It tries to minimize risks and gas consumption limiting the amount of gas sent to
   * the plugin. Since the called function should not be overridden, it should be safe.
   * @param key_ The key of the plugin
   */
  function _resetPluginOnTransfer(bytes32 key_) internal virtual {
    address plugin_ = _pluginAddress(key_);
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
      emit PluginResetAttemptFailed(key_);
    }
  }

  /**
   * @notice If a plugin has been temporarily deAuthorized from transferring the tolen, it
   * removes the lock if the lock is expired
   * @param key_ The key of the plugin
   */
  function _removeLockIfExpired(bytes32 key_) internal virtual {
    if (_pluginByKey[key_].timeLock < block.timestamp) {
      delete _pluginByKey[key_].timeLock;
      _pluginByKey[key_].canManageTransfer = true;
    }
  }

  /**
   * @notice It resets the manager on transfer
   * @param key_ The key of the plugin
   */
  function _resetOnTransfer(bytes32 key_) internal virtual {
    _deleteActors(ManagerConstants.protectorId());
    _deleteActors(ManagerConstants.safeRecipientId());
    // disable all services
    uint256 len = _allPlugins.length;
    for (uint256 i; i < len; ) {
      if (key_ != _allPlugins[i])
        if (_pluginByKey[_allPlugins[i]].canBeReset) _resetPluginOnTransfer(key_);
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
