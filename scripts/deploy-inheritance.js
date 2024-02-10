require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;
const { trustImplementation, bytes4, keccak256 } = require("../test/helpers");
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
  // if (!(await deployUtils.isContractDeployedViaNickSFactory(deployer, "CrunaRegistry", salt))) {
  //   console.error("Registry not deployed on this chain");
  //   process.exit(1);
  // }

  // deploy the plugin
  const plugin = await deployUtils.deployContractViaNickSFactory(deployer, "InheritanceCrunaPlugin", salt);

  // deploy the plugin's proxy
  const proxy = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "InheritanceCrunaPluginProxy",
    ["address"],
    [plugin.address],
    salt,
  );

  const guardian = await deployUtils.attach("CrunaGuardian");
  let PLUGIN_ID = bytes4(keccak256("InheritanceCrunaPlugin"));

  await trustImplementation(guardian, deployer, deployer, process.env.DELAY, PLUGIN_ID, proxy.address, true, 1);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
