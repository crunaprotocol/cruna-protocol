require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  const chainId = await deployUtils.currentChainId();

  const [deployer] = await ethers.getSigners();
  let managerAddress,
    managerProxyAddress,
    guardian,
    guardianAddress,
    inheritancePluginAddress,
    inheritancePluginProxyAddress,
    signatureValidatorAddress,
    vault,
    vaultAddress,
    registry;

  await deployUtils.deployNickSFactory(deployer);

  let crunaRegistryAddress = "0x92ed439eC9c5a9c6554b0733F35e05d4FEdEE547";

  let salt = deployUtils.keccak256("Cruna");
  if (!(await deployUtils.isDeployedViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt))) {
    console.error("Registry not deployed on this chain");
    process.exit(1);
  }

  managerAddress = await deployViaNickSFactory(deployer, "Manager");
  const manager = await deployUtils.attach("Manager", managerAddress);

  guardianAddress = await deployViaNickSFactory(deployer, "Guardian", ["address"], [deployer.address]);
  guardian = await deployUtils.attach("Guardian", guardianAddress);

  managerProxyAddress = await deployViaNickSFactory(deployer, "ManagerProxy", ["address"], [managerAddress]);

  inheritancePluginAddress = await deployViaNickSFactory(deployer, "InheritancePlugin");

  inheritancePluginProxyAddress = await deployViaNickSFactory(
    deployer,
    "InheritancePluginProxy",
    ["address"],
    [inheritancePluginAddress],
  );

  const nameHash = deployUtils.keccak256("InheritancePlugin");
  await deployUtils.Tx(
    guardian.setTrustedImplementation(nameHash, inheritancePluginProxyAddress, true),
    "Setting trusted implementation for InheritancePlugin",
  );

  signatureValidatorAddress = await deployViaNickSFactory(deployer, "SignatureValidator", ["string", "string"], ["Cruna", "1"]);

  await deployViaNickSFactory(deployer, "CrunaFlexiVault", ["address"], [deployer.address]);

  vault = await deployUtils.attach("CrunaFlexiVault");
  await deployUtils.Tx(
    vault.init(crunaRegistryAddress, guardianAddress, signatureValidatorAddress, managerProxyAddress, { gasLimit: 120000 }),
    "Init vault",
  );

  expect(await vault.owner()).to.equal(deployer.address);

  const factory = await deployUtils.deployProxy("VaultFactory", vault.address);

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
