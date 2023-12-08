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

  const registry = await deployUtils.deploy("ERC6551Registry");
  const manager = await deployUtils.deploy("Manager");
  const guardian = await deployUtils.deploy("Guardian", deployer.address);
  const managerProxy = await deployUtils.deploy("ManagerProxy", manager.address);
  const inheritancePlugin = await deployUtils.deploy("InheritancePlugin");
  const inheritancePluginProxy = await deployUtils.deploy("InheritancePluginProxy", inheritancePlugin.address);
  const nameHash = keccak256("InheritancePlugin");
  await deployUtils.Tx(
    guardian.setTrustedImplementation(nameHash, inheritancePluginProxy.address, true),
    "Setting trusted implementation for InheritancePlugin",
  );
  const signatureValidator = await deployUtils.deploy("SignatureValidator", "Cruna", "1");
  const vault = await deployUtils.deploy("CrunaFlexiVault", deployer.address);
  await deployUtils.Tx(
    vault.init(registry.address, guardian.address, signatureValidator.address, managerProxy, address),
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
