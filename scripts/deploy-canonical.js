require("dotenv").config();
const hre = require("hardhat");
const ethers = hre.ethers;
const path = require("path");
const fs = require("fs-extra");
const EthDeployUtils = require("eth-deploy-utils");
let deployUtils;
const canonicalBytecodes = require("../contracts/canonicalBytecodes.json");

async function main() {
  deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);

  let deployer, proposer, executor;
  const chainId = await deployUtils.currentChainId();
  const isLocalhost = chainId === 1337;
  [deployer] = await ethers.getSigners();

  const bytecodesPath = path.resolve(
    __dirname,
    isLocalhost ? "../test/helpers/bytecodes.json" : "../contracts/canonicalBytecodes.json",
  );

  const bytecodes = JSON.parse(fs.readFileSync(bytecodesPath, "utf8"));

  if (isLocalhost) {
    // on localhost, we deploy the factory if not deployed yet
    await deployUtils.deployNickSFactory(deployer);
    // we also deploy the ERC6551Registry if not deployed yet
    await deployUtils.deployBytecodeViaNickSFactory(
      deployer,
      "ERC6551Registry",
      canonicalBytecodes.ERC6551Registry.bytecode,
      "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31",
    );
  }
  await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "ERC7656Registry",
    canonicalBytecodes.ERC7656Registry.bytecode,
    canonicalBytecodes.ERC7656Registry.salt,
  );

  const guardian = await deployUtils.deployBytecodeViaNickSFactory(
    deployer,
    "CrunaGuardian",
    bytecodes.CrunaGuardian.bytecode,
    bytecodes.CrunaGuardian.salt,
  );

  if ([80001, 44787].includes(chainId)) {
    await deployUtils.Tx(guardian.allowUntrusted(true));
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
