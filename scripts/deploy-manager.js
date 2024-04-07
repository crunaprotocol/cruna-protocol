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

  if (!bytecodes.CrunaManager) {
    let salt = ethers.constants.HashZero;
    bytecodes.CrunaManager = {
      salt,
    };
    bytecodes.CrunaManagerProxy = {
      salt,
    };
  }

  if (!bytecodes.CrunaManager.bytecode || process.env.OVERRIDE) {
    bytecodes.CrunaManager.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(deployer, "CrunaManager");
  }

  let manager = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "CrunaManager",
    bytecodes.CrunaManager.bytecode,
    bytecodes.CrunaManager.salt,
  );

  bytecodes.CrunaManager.address = manager.address;

  if (!bytecodes.CrunaManagerProxy.bytecode || process.env.OVERRIDE) {
    bytecodes.CrunaManagerProxy.bytecode = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
      deployer,
      "CrunaManagerProxy",
      ["address"],
      [manager.address],
    );
  }

  let proxy = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "CrunaManagerProxy",
    bytecodes.CrunaManagerProxy.bytecode,
    bytecodes.CrunaManagerProxy.salt,
  );
  bytecodes.CrunaManagerProxy.address = proxy.address;

  fs.writeFileSync(bytecodesPath, JSON.stringify(bytecodes, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
