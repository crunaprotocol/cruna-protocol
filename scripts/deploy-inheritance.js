require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
// const EthDeployUtils = require("../../../Personal/deploy-utils");

let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();
  const [deployer] = await ethers.getSigners();

  process.env.CHAIN_ID = chainId;
  require("./set-canonical");
  const bytecodesPath = path.resolve(__dirname, "../export/deployedBytecodes.json ");

  if (!fs.existsSync(bytecodesPath)) {
    fs.writeFileSync(bytecodesPath, JSON.stringify({}));
  }

  let salt = ethers.utils.HashZero;

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath));

  if (!bytecodes.InheritanceCrunaPlugin) {
    bytecodes.InheritanceCrunaPlugin = {
      salt,
    };
    bytecodes.InheritanceCrunaPluginProxy = {
      salt,
    };
  }

  if (!bytecodes.InheritanceCrunaPlugin.bytecode || process.env.OVERRIDE) {
    bytecodes.InheritanceCrunaPlugin.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
      deployer,
      "InheritanceCrunaPlugin",
    );
  }

  if (bytecodes.InheritanceCrunaPlugin.salt !== salt) {
    bytecodes.InheritanceCrunaPlugin.salt = salt;
  }

  let plugin = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "InheritanceCrunaPlugin",
    bytecodes.InheritanceCrunaPlugin.bytecode,
    salt,
  );

  bytecodes.InheritanceCrunaPlugin.address = plugin.address;

  if (!bytecodes.InheritanceCrunaPluginProxy.bytecode || process.env.OVERRIDE) {
    bytecodes.InheritanceCrunaPluginProxy.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
      deployer,
      "InheritanceCrunaPluginProxy",
      ["address"],
      [plugin.address],
    );
  }

  if (bytecodes.InheritanceCrunaPluginProxy.salt !== salt) {
    bytecodes.InheritanceCrunaPluginProxy.salt = salt;
  }

  let proxy = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "InheritanceCrunaPluginProxy",
    bytecodes.InheritanceCrunaPluginProxy.bytecode,
    salt,
  );
  bytecodes.InheritanceCrunaPluginProxy.address = proxy.address;

  fs.writeFileSync(bytecodesPath, JSON.stringify(bytecodes, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
