require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();

  if (chainId === 1337) {
    // on localhost, we deploy the factory
    await deployUtils.deployNickSFactory(deployer);
  }

  let salt = ethers.constants.HashZero;

  // deploy the manager
  const manager = await deployUtils.deployContractViaNickSFactory(deployer, "CrunaManager", salt);

  // deploy the manager's proxy
  await deployUtils.deployContractViaNickSFactory(deployer, "CrunaManagerProxy", ["address"], [manager.address], salt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
