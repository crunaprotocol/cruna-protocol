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

  process.env.CHAIN_ID = chainId;
  require("./set-canonical");

  if (chainId === 1337) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
  }

  let salt = ethers.constants.HashZero;

  const registry = await deployUtils.attach("CrunaRegistry");

  const guardian = await deployUtils.attach("CrunaGuardian");

  const manager = await deployUtils.deployContractViaNickSFactory(deployer, "CrunaManager", salt);

  const managerProxy = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "CrunaManagerProxy",
    ["address"],
    [manager.address],
    salt,
  );

  const vault = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "CrunaVaults",
    ["uint256", "address[]", "address[]", "address"],
    [process.env.DELAY, [process.env.PROPOSER], [process.env.EXECUTOR], deployer.address],
    salt,
  );

  await deployUtils.Tx(vault.init(managerProxy.address, 1, deployUtils.isMainnet(chainId), { gasLimit: 160000 }), "Init vault");

  const factory = await deployUtils.deployProxy("VaultFactory", vault.address, deployer.address);

  const usdc = await deployUtils.attach("USDCoin");
  const usdt = await deployUtils.attach("TetherUSD");

  await deployUtils.Tx(factory.setPrice(3000, { gasLimit: 60000 }), "Setting price");
  await deployUtils.Tx(factory.setStableCoin(usdc.address, true), "Set USDC as stable coin");
  await deployUtils.Tx(factory.setStableCoin(usdt.address, true), "Set USDT as stable coin");

  // discount campaign selling for $9.9
  await deployUtils.Tx(factory.setDiscount(2010), "Set discount");

  await deployUtils.Tx(vault.setFactory(factory.address, { gasLimit: 100000 }), "Set the factory");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
