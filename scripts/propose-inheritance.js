require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;
const { proposeAndExecute, bytes4, keccak256 } = require("../test/helpers");
const { expect } = require("chai");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const [deployer] = await ethers.getSigners();
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const proposer = new ethers.Wallet(process.env.PROPOSER, ethers.provider);
  // const pluginProxy = await deployUtils.attach("InheritanceCrunaPluginProxy");
  // const plugin = await deployUtils.attach("InheritanceCrunaPlugin", pluginProxy.address);
  const plugin = await deployUtils.attach("InheritanceCrunaPlugin", "0x705366d0a3314283372d335A9AE8971be7274361");
  const guardian = await deployUtils.attach("CrunaGuardian", "0x4DFB2c689A0f87bCeb6C204aCb7e1D0B22139aa2");
  let PLUGIN_ID = bytes4(keccak256("InheritanceCrunaPlugin"));

  // start the process of trusting the plugin
  await proposeAndExecute(
    guardian,
    proposer,
    undefined,
    process.env.DELAY,
    "setTrustedImplementation",
    PLUGIN_ID,
    plugin.address,
    true,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
