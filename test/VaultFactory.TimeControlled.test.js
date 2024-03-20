const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,

  deployCanonical,
  setFakeCanonicalIfCoverage,
} = require("./helpers");

describe("VaultFactory w/ time controlled vault", function () {
  let crunaRegistry, proxy, guardian, erc6551Registry;

  let vault;
  let factory;
  let usdc;
  let deployer, bob, alice, fred, mike, proposer, executor;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mike] = await ethers.getSigners();
    [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("ERC7656Registry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);
  });

  async function initAndDeploy() {
    const managerImpl = await deployContract("CrunaManager");
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);

    const minDelay = 100;

    vault = await deployContract("TimeControlledNFT", minDelay, [proposer.address], [executor.address], deployer.address);

    await vault.init(proxy.address, true, 1, 0);
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
    const nextTokenId = (await vault.nftConf()).nextTokenId;
    const precalculatedAddress = await vault.managerOf(nextTokenId);
    await expect(factory.buyVaults(usdc.address, 1))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, deployer.address, nextTokenId)
      .to.emit(crunaRegistry, "Created")
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
