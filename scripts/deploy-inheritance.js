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

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath));

  if (!bytecodes.InheritanceCrunaPlugin) {
    let salt = ethers.utils.HashZero;
    bytecodes.InheritanceCrunaPlugin = {
      salt,
    };
    bytecodes.InheritanceCrunaPluginProxy = {
      salt,
    };
  }

  if (!bytecodes.InheritanceCrunaPlugin.bytecode || process.env.OVERRIDE) {
    bytecodes.InheritanceCrunaPlugin.bytecode =
      await deployUtils.getBytecodeToBeDeployedViaNickSFactory("InheritanceCrunaPlugin");
  }

  let plugin = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "InheritanceCrunaPlugin",
    bytecodes.InheritanceCrunaPlugin.bytecode,
    bytecodes.InheritanceCrunaPlugin.salt,
  );

  bytecodes.InheritanceCrunaPlugin.address = plugin.address;

  if (!bytecodes.InheritanceCrunaPluginProxy.bytecode || process.env.OVERRIDE) {
    bytecodes.InheritanceCrunaPluginProxy.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
      "InheritanceCrunaPluginProxy",
      ["address"],
      [plugin.address],
    );
  }

  let proxy = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "InheritanceCrunaPluginProxy",
    bytecodes.InheritanceCrunaPluginProxy.bytecode,
    bytecodes.InheritanceCrunaPluginProxy.salt,
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
