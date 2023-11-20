require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const DeployUtils = require("./lib/DeployUtils");
const {normalize} = require("../test/helpers");
let deployUtils;

async function main() {
  deployUtils = new DeployUtils(ethers);
  const chainId = await deployUtils.currentChainId();

  if (!/1337/.test(chainId)) {
    console.log("This script is only for local development");
    process.exit(1);
  }

  const [owner, h1, h2, h3, h4, h5] = await ethers.getSigners();

  let flexiVault, flexiVaultManager;
  let registry, account, proxyWallet, signatureValidator, actorsManager, guardian;
  let usdc, usdt;

  actorsManager = await deployUtils.deploy("ActorsManager");
  guardian = await deployUtils.deploy("AccountGuardian");
  signatureValidator = await deployUtils.deploy("SignatureValidator", "Cruna", "1");

  flexiVault = await deployUtils.deploy("CrunaFlexiVault", actorsManager.address, signatureValidator.address);

  // factory = await deployUtils.deployProxy("CrunaClusterFactory", flexiVault.address);
  // await flexiVault.allowFactoryFor(factory.address, 0);

  registry = await deployUtils.deploy("ERC6551Registry");
  let implementation = await deployUtils.deploy("FlexiAccount", guardian.address);
  proxyWallet = await deployUtils.deploy("AccountProxy", implementation.address);

  flexiVaultManager = await deployUtils.deploy("FlexiVaultManager", flexiVault.address);

  await deployUtils.Tx(
    flexiVaultManager.init(registry.address, proxyWallet.address, {gasLimit: 1500000}),
    "flexiVaultManager.init"
  );

  await deployUtils.Tx(flexiVault.initVault(flexiVaultManager.address, {gasLimit: 150000}), "flexiVault.initVault");

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
