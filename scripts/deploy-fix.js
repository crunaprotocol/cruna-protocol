require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const DeployUtils = require("deploy-utils");
const { normalize, deployContractViaNickSFactory, keccak256, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();

  let registry = await deployUtils.attach("ERC6551Registry");
  let guardian = await deployUtils.attach("Guardian");
  let managerProxy = await deployUtils.attach("ManagerProxy");
  let signatureValidator = await deployUtils.attach("SignatureValidator");

  let vault = await deployUtils.deploy("CrunaFlexiVault", deployer.address);
  // let vault = await deployUtils.attach("CrunaFlexiVault", deployer.address);
  await deployUtils.Tx(
    vault.init(registry.address, guardian.address, signatureValidator.address, managerProxy.address),
    "Init vault",
  );

  let factory = await deployUtils.attach("VaultFactory");

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
