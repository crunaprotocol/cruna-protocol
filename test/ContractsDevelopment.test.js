const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

const {
  cl,
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
  keccak256,
} = require("./helpers");

describe("Testing contract deployments", function () {
  let crunaRegistry, proxy, managerImpl, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor;
  let chainId, ts;
  const delay = 10;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto, proposer, executor] = await ethers.getSigners();

    chainId = await getChainId();
  });

  beforeEach(async function () {
    crunaRegistry = await deployContract("CrunaRegistry");
    managerImpl = await deployContract("CrunaManager");
    guardian = await deployContract("CrunaGuardian", delay, [proposer.address], [executor.address], deployer.address);
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    vault = await deployContract("CrunaVaults", delay, [proposer.address], [executor.address], deployer.address);
    await vault.init(crunaRegistry.address, guardian.address, proxy.address);
    factory = await deployContractUpgradeable("VaultFactoryMock", [vault.address, deployer.address]);
    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  it("should deploy everything as expected", async function () {
    // test the beforeEach
  });

  it("should get the token parameters from the manager", async function () {
    let price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const managerAddress = await vault.managerOf(nextTokenId);
    expect(await ethers.provider.getCode(managerAddress)).equal("0x");
    await factory.connect(bob).buyVaults(usdc.address, 1, true);
    expect(await ethers.provider.getCode(managerAddress)).not.equal("0x");
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    expect(await manager.tokenId()).to.equal(nextTokenId);
    expect(await manager.vault()).to.equal(vault.address);
    expect(await manager.owner()).to.equal(bob.address);
  });
});
