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
    // on localhost, we deploy the factory
    await deployUtils.deployNickSFactory(deployer);
  }

  let salt = ethers.constants.HashZero;

  const registry = await deployUtils.attach("CrunaRegistry");
  const guardian = await deployUtils.attach("CrunaGuardian");
  const managerProxy = await deployUtils.attach("CrunaManagerProxy");

  // deploy the vault
  const vault = await deployUtils.deployContractViaNickSFactory(
    deployer,
    "CrunaVaults",
    ["uint256", "address[]", "address[]", "address"],
    [process.env.DELAY, [process.env.PROPOSER], [process.env.EXECUTOR], deployer.address],
    salt,
  );

  await deployUtils.Tx(
    vault.init(registry.address, guardian.address, managerProxy.address, 1, { gasLimit: 160000 }),
    "Init vault",
  );

  await expect(vault.init(registry.address, guardian.address, managerProxy.address, 1, { gasLimit: 160000 })).revertedWith(
    "Vault: already initialized",
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
