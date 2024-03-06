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

  let salt = ethers.constants.HashZero;
  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath));

  if (!bytecodes.CrunaManager || process.env.OVERRIDE) {
    bytecodes.CrunaManager = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(deployer, "CrunaManager", salt);
  }

  let manager = await deployUtils.deployBytecodeViaNickSFactory(deployer, "CrunaManager", bytecodes.CrunaManager, salt);

  if (!bytecodes.CrunaManagerProxy || process.env.OVERRIDE) {
    bytecodes.CrunaManagerProxy = await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
      deployer,
      "CrunaManagerProxy",
      ["address"],
      [manager.address],
      salt,
    );
  }

  let proxy = await deployUtils.deployBytecodeViaNickSFactory(deployer, "CrunaManagerProxy", bytecodes.CrunaManagerProxy, salt);

  fs.writeFileSync(bytecodesPath, JSON.stringify(bytecodes, null, 2));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
