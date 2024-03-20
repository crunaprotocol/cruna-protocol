const repl = require("repl");
const path = require("path");
const hre = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");
const { expect } = require("chai");

async function main() {
  const deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);
  const [deployer] = await ethers.getSigners();
  const vault = await deployUtils.attach("TimeControlledNFT");
  const factory = await deployUtils.attach("VaultFactory");
  const usdc = await deployUtils.attach("USDCoin");
  const usdt = await deployUtils.attach("TetherUSD");
  const registry = await deployUtils.attach("ERC7656Registry");
  const guardian = await deployUtils.attach("CrunaGuardian");
  const managerProxy = await deployUtils.attach("CrunaManagerProxy");

  function normalize(amount, decimals = 18) {
    return amount + "0".repeat(decimals);
  }

  // Start REPL
  const local = repl.start("> ");

  // Making variables available in the REPL context
  local.context.deployer = deployer.address;
  local.context.du = local.context.deployUtils = deployUtils;
  local.context.vault = vault;
  local.context.factory = factory;
  local.context.usdc = usdc;
  local.context.usdt = usdt;
  local.context.registry = registry;
  local.context.guardian = guardian;
  local.context.managerProxy = managerProxy;
  local.context.normalize = normalize;
  local.context.expect = expect;
  local.context.hre = hre;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
