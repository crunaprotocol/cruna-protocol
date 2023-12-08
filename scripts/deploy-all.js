require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const DeployUtils = require("./lib/DeployUtils");
const { normalize, deployContractViaNickSFactory, keccak256, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(ethers);
  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();
  let manager,
    managerAddress,
    flexiProxy,
    managerProxyAddress,
    guardian,
    guardianAddress,
    inheritancePlugin,
    inheritancePluginAddress,
    inheritancePluginProxy,
    inheritancePluginProxyAddress,
    signatureValidator,
    signatureValidatorAddress,
    vault,
    vaultAddress,
    erc6551Registry,
    registry;

  let erc6551RegistryAddress = "0x000000006551c19487814612e58FE06813775758";
  registry = await deployUtils.attach("ERC6551Registry", erc6551RegistryAddress);
  try {
    let salt = keccak256("ERC6551Registry");
    let implementation = "0xdD2FD4581271e230360230F9337D5c0430Bf44C0";
    let tokenContract = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199";

    await registry.account(implementation, salt, chainId, tokenContract, 1);
  } catch (e) {
    registry = await deployContract("ERC6551Registry");
    erc6551RegistryAddress = registry.address;
  }

  managerAddress = await deployContractViaNickSFactory(deployer, "Manager");
  await deployUtils.saveDeployed(chainId, ["Manager"], [managerAddress]);
  console.log("Manager deployed at", managerAddress);

  guardianAddress = await deployContractViaNickSFactory(deployer, "Guardian", ["address"], [deployer.address]);
  await deployUtils.saveDeployed(chainId, ["Guardian"], [guardianAddress]);
  guardian = await deployUtils.attach("Guardian", guardianAddress);
  console.log("Guardian deployed at", guardianAddress);

  managerProxyAddress = await deployContractViaNickSFactory(deployer, "ManagerProxy", ["address"], [managerAddress]);
  await deployUtils.saveDeployed(chainId, ["ManagerProxy"], [managerProxyAddress]);
  console.log("Proxy deployed at", managerProxyAddress);

  inheritancePluginAddress = await deployContractViaNickSFactory(deployer, "InheritancePlugin");
  await deployUtils.saveDeployed(chainId, ["InheritancePlugin"], [inheritancePluginAddress]);
  console.log("InheritancePlugin deployed at", inheritancePluginAddress);

  inheritancePluginProxyAddress = await deployContractViaNickSFactory(
    deployer,
    "InheritancePluginProxy",
    ["address"],
    [inheritancePluginAddress],
  );
  await deployUtils.saveDeployed(chainId, ["InheritancePluginProxy"], [inheritancePluginProxyAddress]);
  console.log("InheritancePluginProxy deployed at", inheritancePluginProxyAddress);

  const nameHash = keccak256("InheritancePlugin");
  await deployUtils.Tx(
    guardian.setTrustedImplementation(nameHash, inheritancePluginProxyAddress, true),
    "Setting trusted implementation for InheritancePlugin",
  );

  signatureValidatorAddress = await deployContractViaNickSFactory(
    deployer,
    "SignatureValidator",
    ["string", "string"],
    ["Cruna", "1"],
  );
  await deployUtils.saveDeployed(chainId, ["SignatureValidator"], [signatureValidatorAddress]);
  console.log("SignatureValidator deployed at", signatureValidatorAddress);

  vaultAddress = await deployContractViaNickSFactory(deployer, "CrunaFlexiVault", ["address"], [deployer.address]);
  await deployUtils.saveDeployed(chainId, ["CrunaFlexiVault"], [vaultAddress]);
  console.log("CrunaFlexiVault deployed at", vaultAddress);

  vault = await deployUtils.attach("CrunaFlexiVault");
  await deployUtils.Tx(
    vault.init(erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, managerProxyAddress),
    "Init vault",
  );

  expect(await vault.owner()).to.equal(deployer.address);

  const factory = await deployUtils.deployProxy("VaultFactory", vault.address);

  const usdc = await deployUtils.attach("USDCoin");
  const usdt = await deployUtils.attach("TetherUSD");

  await deployUtils.Tx(factory.setPrice(3000, { gasLimit: 60000 }), "Setting price");
  await deployUtils.Tx(factory.setStableCoin(usdc.address, true), "Set USDC as stable coin");
  await deployUtils.Tx(factory.setStableCoin(usdt.address, true), "Set USDT as stable coin");

  // discount campaign selling for $9.9
  await deployUtils.Tx(factory.setDiscount(67), "Set promo code");

  await deployUtils.Tx(vault.setFactory(factory.address, { gasLimit: 100000 }), "Set the factory");

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
