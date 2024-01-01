require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
const { normalize, deployContractViaNickSFactory, keccak256, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);
  const [deployer] = await ethers.getSigners();
  const usdt = await deployUtils.deploy("TetherUSD");
  await deployUtils.Tx(usdt.mint(deployer.address, normalize("1000000", 6)), "Minting USDT");
  const usdc = await deployUtils.deploy("USDCoin");
  await deployUtils.Tx(usdc.mint(deployer.address, normalize("1000000")), "Minting USDC");

  console.log(`
  
All deployed. Look at export/deployed.json for the deployed addresses.
`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
