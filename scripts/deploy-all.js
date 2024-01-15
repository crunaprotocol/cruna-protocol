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

  if (chainId === 1337) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
  }

  let salt = deployUtils.keccak256("Cruna");

  const registry = await deployUtils.deployContractViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt);

  const guardian = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "Guardian",
    ["uint256", "address[]", "address[]", "address"],
    [process.env.DELAY, [process.env.PROPOSER], [process.env.EXECUTOR], deployer.address],
    salt,
  );

  const manager = await deployUtils.deployContractViaNickSFactory(deployer, "Manager", salt);

  const managerProxy = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "ManagerProxy",
    ["address"],
    [manager.address],
    salt,
  );

  // const plugin = await deployUtils.deployContractViaNickSFactory(deployer, "InheritancePlugin", salt);
  //
  // // deploy the plugin's proxy
  // const proxy = await deployUtils.deployContractViaNickSFactory(
  //   deployer,
  //   "InheritancePluginProxy",
  //   ["address"],
  //   [plugin.address],
  //   salt,
  // );
  //
  // await deployUtils.Tx(
  //   guardian.setTrustedImplementation(deployUtils.bytes4(deployUtils.keccak256("InheritancePlugin")), proxy.address, true, 1),
  //   "Setting trusted implementation for InheritancePlugin",
  // );

  const vault = await deployUtils.deployContractViaNickSFactory(deployer, "VaultMock", ["address"], [deployer.address], salt);

  try {
    await deployUtils.Tx(
      vault.init(registry.address, guardian.address, managerProxy.address, { gasLimit: 120000 }),
      "Init vault",
    );
  } catch (e) {
    // we are calling the script again
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
