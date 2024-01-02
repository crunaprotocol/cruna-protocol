require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
const { normalize, deployContractViaNickSFactory, keccak256, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");
const [, , address] = process.argv;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);
  const [deployer] = await ethers.getSigners();
  const usdt = await deployUtils.attach("TetherUSD");
  const usdc = await deployUtils.attach("USDCoin");

  await deployUtils.Tx(usdt.mint(process.env.TO, normalize("1000000", 6)), "Minting USDT");
  await deployUtils.Tx(usdc.mint(process.env.TO, normalize("1000000")), "Minting USDC");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
