// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
require("dotenv").config();
const hre = require("hardhat");

const ethers = hre.ethers;
const deployed = require("../export/deployed.json");
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);
  const chainId = await deployUtils.currentChainId();

  const contractName = process.env.CONTRACT;
  const gasLimit = parseInt(process.env.GAS_LIMIT || "0");

  // const address = deployed[chainId][contract];
  // const Contract = await ethers.getContractFactory(contract);
  // console.log("Upgrading", contract);
  // await upgrades.upgradeProxy(address, Contract, gasLimit ? {gasLimit} : {});
  // console.log("Done");
  await deployUtils.upgradeProxy(contractName, gasLimit);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
