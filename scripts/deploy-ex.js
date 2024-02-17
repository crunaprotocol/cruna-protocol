require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

const { expect } = require("chai");

async function main() {
  async function simulateDeployContractViaNickSFactory(
    deployer,
    contractName,
    constructorTypes,
    constructorArgs,
    salt,
    extraParams = {},
  ) {
    if (!salt && !Array.isArray(constructorTypes)) {
      salt = constructorTypes;
      constructorTypes = undefined;
      constructorArgs = undefined;
    }
    if (!salt) {
      salt = ethers.constants.HashZero;
    }
    const json = await artifacts.readArtifact(contractName);
    let contractBytecode = json.bytecode;
    if (constructorTypes) {
      const encodedArgs = ethers.utils.defaultAbiCoder.encode(constructorTypes, constructorArgs);
      contractBytecode = contractBytecode + encodedArgs.substring(2);
    }

    const address = ethers.utils.getCreate2Address(
      "0x4e59b44847b379578588920ca78fbf26c0b4956c",
      salt,
      ethers.utils.keccak256(contractBytecode),
    );
    console.log("address", address);

    const data = salt + contractBytecode.substring(2);
    return Object.assign({
      to: "0x4e59b44847b379578588920ca78fbf26c0b4956c",
      data},
        extraParams);
  }

  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer, proposer, executor;
  const chainId = await deployUtils.currentChainId();
  [deployer] = await ethers.getSigners();

  let proposerAddress = process.env.PROPOSER;
  let executorAddress = process.env.EXECUTOR;
  let delay = process.env.DELAY;

  let salt = ethers.constants.HashZero;

  let rawTx = await simulateDeployContractViaNickSFactory(deployer, "CrunaRegistry", undefined, undefined, salt, {gasLimit: 200000, gasPrice: 100n * 10n ** 9n});

  console.log("tx", rawTx);

  const wallet = new ethers.Wallet(process.env.DEPLOYER, ethers.provider);

  const serializedTx = await wallet.signTransaction(rawTx);

  console.log("signedTx", serializedTx);

  let txResponse = await ethers.provider.sendTransaction(serializedTx);
  await txResponse.wait();

  // await deployUtils.deployContractViaNickSFactory(
  //   deployer,
  //   "CrunaGuardian",
  //   ["uint256", "address[]", "address[]", "address"],
  //   [delay, [proposerAddress], [executorAddress], deployer.address],
  //   salt,
  // );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
