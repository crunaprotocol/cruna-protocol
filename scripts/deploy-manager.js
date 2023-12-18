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
  let managerAddress;

  await deployUtils.deployNickSFactory(deployer);

  let salt = deployUtils.keccak256("Cruna");
  if (!(await deployUtils.isDeployedViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt))) {
    console.error("Registry not deployed on this chain");
    process.exit(1);
  }

  managerAddress = await deployUtils.deployContractViaNickSFactory(deployer, "Manager", undefined, undefined, salt);
  const manager = await deployUtils.attach("Manager", managerAddress);
  expect(await manager.owner()).to.equal(deployer.address);

  console.log(`Done.`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
