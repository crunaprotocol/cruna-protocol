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
  executeAndReturnGasCost,
  signRequest,
  selectorId,
  deployCanonical,
} = require("./helpers");

describe("Unmanaged service", function () {
  let crunaRegistry, proxy, guardian, erc6551Registry;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mike, proposer, executor;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;
  let fungibleService;
  let salt = ethers.constants.HashZero;

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
    vault = await deployContract("OwnableNFT", deployer.address);

    await vault.init(proxy.address, true, 1, 0);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(deployer.address, normalize("900"));
    await usdc.mint(bob.address, normalize("900"));
    await usdc.mint(fred.address, normalize("900"));
    await usdc.mint(alice.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));
    await usdc.mint(mike.address, normalize("600"));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;

    fungibleService = await deployContract("FungibleService");
    expect(await fungibleService.version()).equal(1e6);
    expect(await fungibleService.isERC6551Account()).equal(false);
  }

  describe("Buy vaults", function () {
    //here we test the contract
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should buy a vault", async function () {
      let price = await factory.finalPrice(usdc.address);
      await usdc.connect(bob).approve(factory.address, price);
      const nextTokenId = (await vault.nftConf()).nextTokenId;
      const precalculatedAddress = await vault.managerOf(nextTokenId);
      await expect(factory.connect(bob).buyVaults(usdc.address, 1))
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

      // deploy a fungible service

      const fungibleAt = await vault.addressOfDeployed(fungibleService.address, salt, nextTokenId, false);

      const data = ethers.utils.defaultAbiCoder.encode(
        ["string", "string"], // Types of the parameters
        ["CIP Token", "CIPT"], // Values to encode
      );

      await vault.connect(bob).plug(fungibleService.address, salt, nextTokenId, false, data);

      fungibleService = await ethers.getContractAt("FungibleService", fungibleAt);
      expect(await fungibleService.name()).equal(`CIP Token`);
      expect(await fungibleService.symbol()).equal(`CIPT`);
      expect(await fungibleService.extraName()).equal(`FT ${await vault.name()} #${nextTokenId}`);
    });
  });
});
