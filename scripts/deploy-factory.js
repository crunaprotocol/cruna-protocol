require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const DeployUtils = require("deploy-utils");
const { normalize, deployContractViaNickSFactory, keccak256 } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(path.resolve(__dirname, ".."), console.log);
  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();

  const vault = await deployUtils.attach("CrunaFlexiVault");

  expect(await vault.owner()).to.equal(deployer.address);

  const factory = await deployUtils.deployProxy("VaultFactory", vault.address);
  // const factory = await deployUtils.attach("VaultFactory");

  const usdc = await deployUtils.attach("USDCoin");
  const usdt = await deployUtils.attach("TetherUSD");

  await deployUtils.Tx(factory.setPrice(3000, { gasLimit: 60000 }), "Setting price");
  await deployUtils.Tx(factory.setStableCoin(usdc.address, true), "Set USDC as stable coin");
  await deployUtils.Tx(factory.setStableCoin(usdt.address, true), "Set USDT as stable coin");

  // discount campaign selling for $9.9
  await deployUtils.Tx(factory.setDiscount(67), "Set promo code");

  await deployUtils.Tx(vault.setFactory(factory.address, { gasLimit: 100000 }), "Set the factory");

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
