require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer, proposer, executor;
  const chainId = await deployUtils.currentChainId();
  const isLocalhost = chainId === 1337;

  if (isLocalhost) {
    [deployer, proposer, executor] = await ethers.getSigners();
  } else {
    [deployer] = await ethers.getSigners();
  }

  let proposerAddress = isLocalhost ? proposer.address : process.env.PROPOSER_ADDRESS;
  let executorAddress = isLocalhost ? executor.address : process.env.EXECUTOR_ADDRESS;
  let delay = isLocalhost ? 10 : process.env.DELAY;

  if (isLocalhost) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
  }
  const bytecodesPath = path.resolve(
    __dirname,
    isLocalhost ? "../test/helpers/bytecodes.json" : "../contracts/canonicalBytecodes.json",
  );

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));

  // This is supposed to happen only during development when there are breaking changes.
  // It should not happen after the first guardian as been deployed, except if very serious
  // issues are found and a new guardian is needed. In that unfortunate case, all managers
  // and plugins will have to be upgraded by tokens' owners.
  console.log(
    "Code changed:",
    bytecodes.CrunaGuardian.bytecode ===
      (await deployUtils.getBytecodeToBeDeployedViaNickSFactory(
        deployer,
        "CrunaGuardian",
        ["uint256", "address[]", "address[]", "address"],
        [delay, [proposerAddress], [executorAddress], deployer.address],
      )),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
