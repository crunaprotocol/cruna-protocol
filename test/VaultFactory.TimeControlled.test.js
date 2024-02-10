const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  cl,
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  deployAll,
  upgradeProxy,
  executeAndReturnGasCost,
  signRequest,
  selectorId,
} = require("./helpers");

describe("VaultFactory w/ time controlled vault", function () {
  let registry, proxy, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mike, proposer, executor;
  const delay = 10;

  before(async function () {
    [deployer, bob, alice, fred, mike, proposer, executor] = await ethers.getSigners();
    // we test the deploying using Nick's factory only here because if not it would create conflicts, since any contract has already been deployed and would not change its storage
    // [registry, proxy, guardian] = await deployAll(deployer, proposer, executor, delay);
  });

  async function initAndDeploy() {
    // process.exit();

    registry = await deployContract("CrunaRegistry");
    const managerImpl = await deployContract("CrunaManager");
    guardian = await deployContract("CrunaGuardian", delay, [proposer.address], [executor.address], deployer.address);
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);

    const minDelay = 100;

    vault = await deployContract("CrunaVaults", minDelay, [proposer.address], [executor.address], deployer.address);
    await vault.init(registry.address, guardian.address, proxy.address, 1);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);

    await usdc.mint(deployer.address, normalize("900"));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
  }

  //here we test the contract
  beforeEach(async function () {
    await initAndDeploy();
  });

  it("should buy a vault", async function () {
    let price = await factory.finalPrice(usdc.address);
    await usdc.approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const precalculatedAddress = await vault.managerOf(nextTokenId);
    await expect(factory.buyVaults(usdc.address, 1))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, deployer.address, nextTokenId)
      .to.emit(registry, "BoundContractCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(proxy.address),
        "0x" + "0".repeat(64),
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );
  });
});
