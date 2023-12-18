require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const DeployUtils = require("deploy-utils");
let deployUtils;

const { expect } = require("chai");

async function main() {
  deployUtils = new DeployUtils(path.resolve(__dirname, ".."), console.log);

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

  let erc6551RegistryAddress = "0x000000006551c19487814612e58FE06813775758";
  registry = await deployUtils.attach("CrunaRegistry", erc6551RegistryAddress);
  try {
    let salt = deployUtils.keccak256("CrunaRegistry");
    let implementation = "0xdD2FD4581271e230360230F9337D5c0430Bf44C0";
    let tokenContract = "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199";

    await registry.bondContract(implementation, salt, chainId, tokenContract, 1);
  } catch (e) {
    registry = await deployUtils.deploy("CrunaRegistry");
    erc6551RegistryAddress = registry.address;
  }

  async function deployIfNotDeployed(
    deployer,
    contractName,
    constructorTypes,
    constructorArgs,
    salt = deployUtils.keccak256("Cruna"),
  ) {
    let address = await deployUtils.getAddressViaNickSFactory(deployer, contractName, constructorTypes, constructorArgs, salt);
    let contract = await deployUtils.attach(contractName, address);
    try {
      await contract.version();
      console.log("Already deployed", contractName);
    } catch (e) {
      // console.log(e)
      // not deployed yet
      address = await deployUtils.deployViaNickSFactory(deployer, contractName, constructorTypes, constructorArgs, salt);
    }

    return address;
  }

  managerAddress = await deployIfNotDeployed(deployer, "Manager");
  const manager = await deployUtils.attach("Manager", managerAddress);
  expect(await manager.owner()).to.equal(deployer.address);

  guardianAddress = await deployIfNotDeployed(deployer, "Guardian", ["address"], [deployer.address]);
  guardian = await deployUtils.attach("Guardian", guardianAddress);

  managerProxyAddress = await deployIfNotDeployed(deployer, "ManagerProxy", ["address"], [managerAddress]);

  inheritancePluginAddress = await deployIfNotDeployed(deployer, "InheritancePlugin");

  inheritancePluginProxyAddress = await deployIfNotDeployed(
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

  signatureValidatorAddress = await deployIfNotDeployed(deployer, "SignatureValidator", ["string", "string"], ["Cruna", "1"]);

  await deployIfNotDeployed(deployer, "CrunaFlexiVault", ["address"], [deployer.address]);

  vault = await deployUtils.attach("CrunaFlexiVault");
  await deployUtils.Tx(
    vault.init(erc6551RegistryAddress, guardianAddress, signatureValidatorAddress, managerProxyAddress, { gasLimit: 120000 }),
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
