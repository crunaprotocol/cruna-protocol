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
  await deployUtils.Tx(
    guardian.setTrustedImplementation(
      deployUtils.bytes4(deployUtils.keccak256("InheritanceCrunaPlugin")),
      proxy.address,
      true,
      1,
    ),
    "Setting trusted implementation for InheritanceCrunaPlugin",
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
