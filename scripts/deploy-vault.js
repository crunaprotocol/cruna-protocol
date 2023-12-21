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

  let salt = deployUtils.keccak256("Cruna");

  if (!(await deployUtils.isContractDeployedViaNickSFactory(deployer, "CrunaRegistry", salt))) {
    console.error("Registry not deployed on this chain");
    process.exit(1);
  }
  const registry = await deployUtils.attach("CrunaRegistry");

  if (!(await deployUtils.isContractDeployedViaNickSFactory(deployer, "Guardian", ["address"], [deployer.address], salt))) {
    console.error("Guardian not deployed on this chain");
    process.exit(1);
  }
  const guardian = await deployUtils.attach("Guardian");

  if (!(await deployUtils.isContractDeployedViaNickSFactory(deployer, "Manager", salt))) {
    console.error("Manager not deployed on this chain");
    process.exit(1);
  }
  const manager = await deployUtils.attach("Manager");

  if (!(await deployUtils.isContractDeployedViaNickSFactory(deployer, "ManagerProxy", ["address"], [manager.address], salt))) {
    console.error("ManagerProxy not deployed on this chain");
    process.exit(1);
  }
  const managerProxy = await deployUtils.attach("ManagerProxy");

  // deploy the vault
  const vault = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "CrunaFlexiVault",
    ["address"],
    [deployer.address],
    salt,
  );

  await deployUtils.Tx(
    vault.init(registry.address, guardian.address, managerProxy.address, { gasLimit: 120000 }),
    "Init vault",
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
