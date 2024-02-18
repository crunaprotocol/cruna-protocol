require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();

  if (chainId === 1337) {
    // on localhost, we deploy the factory
    await deployUtils.deployNickSFactory(deployer);
  }

  const salt = ethers.constants.HashZero;

  // deploy the plugin
  const plugin = await deployUtils.deployContractViaNickSFactory(deployer, "InheritanceCrunaPlugin", salt);

  // deploy the plugin's proxy
  await deployUtils.deployContractViaNickSFactory(deployer, "InheritanceCrunaPluginProxy", ["address"], [plugin.address], salt);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
