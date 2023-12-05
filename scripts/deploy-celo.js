require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const DeployUtils = require("./lib/DeployUtils");
const { normalize, deployContractViaNickSFactory, keccak256 } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(ethers);
  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();
  let manager,
    managerAddress,
    flexiProxy,
    flexiProxyAddress,
    guardian,
    guardianAddress,
    inheritancePlugin,
    inheritancePluginAddress,
    inheritancePluginProxy,
    inheritancePluginProxyAddress,
    signatureValidator,
    signatureValidatorAddress,
    vault,
    vaultAddress;

  const erc6551RegistryAddress = "0x000000006551c19487814612e58FE06813775758";

  manager = await deployUtils.attach("Manager");
  try {
    await manager.version();
    managerAddress = manager.address;
  } catch (e) {
    managerAddress = await deployContractViaNickSFactory(deployer, "Manager");
    await deployUtils.saveDeployed(chainId, ["Manager"], [managerAddress]);
    console.log("Manager deployed at", managerAddress);
  }

  try {
    guardian = await deployUtils.attach("FlexiGuardian");
    await guardian.version();
    guardianAddress = guardian.address;
  } catch (e) {
    guardianAddress = await deployContractViaNickSFactory(deployer, "FlexiGuardian", ["address"], [deployer.address]);
    await deployUtils.saveDeployed(chainId, ["FlexiGuardian"], [guardianAddress]);
    console.log("Guardian deployed at", guardianAddress);
  }

  try {
    flexiProxy = await deployUtils.attach("FlexiProxy");
    await flexiProxy.isProxy();
    flexiProxyAddress = flexiProxy.address;
  } catch (e) {
    flexiProxyAddress = await deployContractViaNickSFactory(deployer, "FlexiProxy", ["address"], [managerAddress]);
    await deployUtils.saveDeployed(chainId, ["FlexiProxy"], [flexiProxyAddress]);
    console.log("Proxy deployed at", flexiProxyAddress);
  }

  try {
    inheritancePlugin = await deployUtils.attach("InheritancePlugin");
    await inheritancePlugin.version();
    inheritancePluginAddress = inheritancePlugin.address;
  } catch (e) {
    inheritancePluginAddress = await deployContractViaNickSFactory(deployer, "InheritancePlugin");
    await deployUtils.saveDeployed(chainId, ["InheritancePlugin"], [inheritancePluginAddress]);
    console.log("InheritancePlugin deployed at", inheritancePluginAddress);
  }

  try {
    inheritancePluginProxy = await deployUtils.attach("InheritancePluginProxy");
    await inheritancePluginProxy.isProxy();
    inheritancePluginProxyAddress = inheritancePluginProxy.address;
  } catch (e) {
    inheritancePluginProxyAddress = await deployContractViaNickSFactory(
      deployer,
      "InheritancePluginProxy",
      ["address"],
      [inheritancePluginAddress],
    );
    await deployUtils.saveDeployed(chainId, ["InheritancePluginProxy"], [inheritancePluginProxyAddress]);
    console.log("InheritancePluginProxy deployed at", inheritancePluginProxyAddress);

    const scope = keccak256("InheritancePlugin");
    await deployUtils.Tx(
      guardian.setTrustedImplementation(scope, inheritancePluginProxy.address, true),
      "Setting trusted implementation for InheritancePlugin",
    );
  }

  try {
    signatureValidator = await deployUtils.attach("SignatureValidator");
    await signatureValidator.version();
    signatureValidatorAddress = signatureValidator.address;
  } catch (e) {
    signatureValidatorAddress = await deployContractViaNickSFactory(
      deployer,
      "SignatureValidator",
      ["string", "string"],
      ["Cruna", "1"],
    );
    await deployUtils.saveDeployed(chainId, ["SignatureValidator"], [signatureValidatorAddress]);
    console.log("SignatureValidator deployed at", signatureValidatorAddress);
  }

  vaultAddress = await deployContractViaNickSFactory(deployer, "CrunaFlexiVault", ["address"], [deployer.address]);
  await deployUtils.saveDeployed(chainId, ["CrunaFlexiVault"], [vaultAddress]);
  console.log("CrunaFlexiVault deployed at", vaultAddress);
  vault = await deployUtils.attach("CrunaFlexiVault");
  await deployUtils.Tx(
    vault.init(erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, flexiProxyAddress),
    "Init vault",
  );

  console.log(`
  
All deployed. Look at export/deployed.json for the deployed addresses.
`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
