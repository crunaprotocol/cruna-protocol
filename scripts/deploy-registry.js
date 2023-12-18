require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const DeployUtils = require("deploy-utils");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();
  const [deployer] = await ethers.getSigners();
  let registry;

  if (chainId === 1337) {
    // on localhost, we deploy the factory
    await deployUtils.deployNickSFactory(deployer);
  }

  let salt = deployUtils.keccak256("Cruna");
  await deployUtils.deployViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt);

  console.log(`Done.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
