const repl = require("repl");
const path = require("path");
const hre = require("hardhat");
const EthDeployUtils = require("eth-deploy-utils");

async function main() {
  const deployUtils = new EthDeployUtils(path.resolve(__dirname, ".."), console.log);
  const vault = await deployUtils.attach("CrunaFlexiVault");
  const factory = await deployUtils.attach("VaultFactory");
  const usdc = await deployUtils.attach("USDCoin");
  const usdt = await deployUtils.attach("TetherUSD");

  function normalize(amount, decimals = 18) {
    return amount + "0".repeat(decimals);
  }

  // Start REPL
  const local = repl.start("> ");

  // Making variables available in the REPL context
  local.context.vault = vault;
  local.context.factory = factory;
  local.context.usdc = usdc;
  local.context.usdt = usdt;
  local.context.normalize = normalize;
  local.context.hre = hre;
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
