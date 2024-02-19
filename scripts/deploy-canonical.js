require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
// const EthDeployUtils = require("../../../Personal/deploy-utils");
const bytecodes = require("../test/helpers/bytecodes.json");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer, proposer, executor;
  const chainId = await deployUtils.currentChainId();
  [deployer] = await ethers.getSigners();

  let proposerAddress = process.env.PROPOSER_ADDRESS;
  let executorAddress = process.env.EXECUTOR_ADDRESS;
  let delay = process.env.DELAY;

  if (chainId === 1337) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
    // we also deploy the ERC6551Registry if not deployed yet
    await deployUtils.deployBytecodeViaNickSFactory(
      deployer,
      "ERC6551Registry",
      bytecodes.ERC6551Registry,
      "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31",
    );
  }

  let salt = ethers.constants.HashZero;

  await deployUtils.deployContractViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt);

  await deployUtils.deployContractViaNickSFactory(
    deployer,
    "CrunaGuardian",
    ["uint256", "address[]", "address[]", "address"],
    [delay, [proposerAddress], [executorAddress], deployer.address],
    salt,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
