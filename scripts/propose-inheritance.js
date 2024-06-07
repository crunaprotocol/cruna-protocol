require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");

const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;
const { proposeAndExecute, bytes4, keccak256, selectorId } = require("../test/helpers");
const { expect } = require("chai");

async function trustImplementation(guardian, proposer, delay, implementation, trusted) {
  const bytes = ethers.utils.defaultAbiCoder.encode(
    ["bytes4", "address", "bool"],
    [await selectorId("ICrunaGuardian", "trust"), implementation, trusted],
  );
  const operation = ethers.utils.keccak256(bytes);
  await expect(guardian.connect(proposer).trust(delay, 0, implementation, trusted, { gasLimit: 200000 }))
    .emit(guardian, "OperationProposed")
    .withArgs(operation, proposer.address, delay);
}

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const [deployer] = await ethers.getSigners();
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const proposer = new ethers.Wallet(process.env.PROPOSER, ethers.provider);

  const bytecodesPath = path.resolve(__dirname, "../contracts/canonicalBytecodes.json");
  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));

  const plugin = await deployUtils.attach("InheritanceCrunaPluginProxy");
  const guardian = await deployUtils.attach("CrunaGuardian", bytecodes.CrunaGuardian.address);

  // start the process of trusting the plugin
  await trustImplementation(guardian, proposer, process.env.DELAY, plugin.address, true);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
