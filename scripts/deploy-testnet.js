require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const DeployUtils = require("./lib/DeployUtils");
const { normalize, deployContractViaNickSFactory, keccak256, deployContract } = require("../test/helpers");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(ethers);

  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();

  let registry = await deployUtils.attach("ERC6551Registry");
  let manager = await deployUtils.deploy("Manager");
  let guardian = await deployUtils.deploy("Guardian", deployer.address);
  let managerProxy = await deployUtils.deploy("ManagerProxy", manager.address);
  let inheritancePlugin = await deployUtils.deploy("InheritancePlugin");
  let inheritancePluginProxy = await deployUtils.deploy("InheritancePluginProxy", inheritancePlugin.address);
  let nameHash = keccak256("InheritancePlugin");
  await deployUtils.Tx(
    guardian.setTrustedImplementation(nameHash, inheritancePluginProxy.address, true),
    "Setting trusted implementation for InheritancePlugin",
  );
  let signatureValidator = await deployUtils.deploy("SignatureValidator", "Cruna", "1");

  let vault = await deployUtils.deploy("CrunaFlexiVault", deployer.address);
  await deployUtils.Tx(
    vault.init(registry.address, guardian.address, signatureValidator.address, managerProxy.address),
    "Init vault",
  );

  expect(await vault.owner()).to.equal(deployer.address);

  let factory = await deployUtils.deployProxy("VaultFactory", vault.address);

  let usdc = await deployUtils.deploy("USDCoin");
  let usdt = await deployUtils.deploy("TetherUSD");

  await deployUtils.Tx(usdc.mint(deployer.address, normalize("1000000")), "Minting USDC");
  await deployUtils.Tx(usdt.mint(deployer.address, normalize("1000000", 6)), "Minting USDT");

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
