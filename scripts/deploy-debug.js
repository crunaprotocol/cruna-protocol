require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const DeployUtils = require("./lib/DeployUtils");
const { normalize, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(ethers);
  const chainId = await deployUtils.currentChainId();

  if (!/1337/.test(chainId)) {
    console.log("This script is only for local development");
    process.exit(1);
  }

  const [deployer] = await ethers.getSigners();

  const erc6551Registry = await deployUtils.deploy("ERC6551Registry");
  const managerImpl = await deployUtils.deploy("Manager");
  const guardian = await deployUtils.deploy("Guardian", deployer.address);
  const managerProxy = await deployUtils.deploy("FlexiProxy", managerImpl.address);

  const inheritancePluginImpl = await deployUtils.deploy("InheritancePlugin");
  const inheritancePluginProxy = await deployUtils.deploy("InheritancePluginProxy", inheritancePluginImpl.address);

  const signatureValidator = await deployUtils.deploy("SignatureValidator", "Cruna", "1");

  const vault = await deployUtils.deploy(
    "CrunaFlexiVault",
    erc6551Registry.address,
    guardian.address,
    signatureValidator.address,
    managerProxy.address,
  );
  const factory = await deployUtils.deployProxy("VaultFactory", vault.address);

  await deployUtils.Tx(vault.setFactory(factory.address), "Set the factory");

  const usdc = await deployUtils.deploy("USDCoin");
  const usdt = await deployUtils.deploy("TetherUSD");

  // to get USDC and USDT on local development set a variable
  // DOLLAR_RECEIVER in the .env
  if (process.env.DOLLAR_RECEIVER) {
    await deployUtils.Tx(usdc.mint(process.env.DOLLAR_RECEIVER, normalize("900")), "Minting USDC");
    await deployUtils.Tx(usdt.mint(process.env.DOLLAR_RECEIVER, normalize("600", 6)), "Minting USDT");
  }

  await deployUtils.Tx(factory.setPrice(990), "Setting price");
  await deployUtils.Tx(factory.setStableCoin(usdc.address, true), "Set USDC as stable coin");
  await deployUtils.Tx(factory.setStableCoin(usdt.address, true), "Set USDT as stable coin");

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
