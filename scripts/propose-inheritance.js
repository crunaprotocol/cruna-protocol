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

  const proposer = new ethers.Wallet(process.env.PROPOSER, ethers.provider);
  const pluginProxy = await deployUtils.attach("InheritanceCrunaPluginProxy");
  const plugin = await deployUtils.attach("InheritanceCrunaPlugin", pluginProxy.address);
  const guardian = await deployUtils.attach("CrunaGuardian");
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
    1,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
