const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
const { Contract } = require("@ethersproject/contracts");
const EthDeployUtils = require("eth-deploy-utils");
const deployUtils = new EthDeployUtils();

const {
  amount,
  cl,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
  keccak256,
  bytes4,
  combineBytes4ToBytes32,
  getInterfaceId,
  selectorId,
  trustImplementation,
} = require("./helpers");

describe("CrunaManager : Protectors", function () {
  let crunaRegistry, proxy, managerImpl, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor;
  let selector;
  // we put it very short for convenience (test-only)
  const delay = 10;
  let chainId;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto, proposer, executor] = await ethers.getSigners();
    chainId = await getChainId();
    selector = await selectorId("ICrunaManager", "setProtector");
  });

  beforeEach(async function () {
    crunaRegistry = await deployContract("CrunaRegistry");
    managerImpl = await deployContract("CrunaManager");
    guardian = await deployContract("CrunaGuardian", delay, [proposer.address], [executor.address], deployer.address);
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);

    vault = await deployContract("VaultMockSimple", deployer.address);
    await vault.init(crunaRegistry.address, guardian.address, proxy.address, 1);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);

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

  const buyAVault = async (bob, managerProxy = proxy) => {
    const price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const precalculatedAddress = await vault.managerOf(nextTokenId);

    // console.log(keccak256("TokenLinkedContractCreated(address,address,bytes32,uint256,address,uint256)"))

    await expect(factory.connect(bob).buyVaults(usdc.address, 1))
      .to.emit(crunaRegistry, "TokenLinkedContractCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(managerProxy.address),
        "0x" + "0".repeat(64),
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );

    return nextTokenId;
  };

  it("should allow bob to upgrade the manager", async function () {
    const tokenId = await buyAVault(bob);
    const managerV2Impl = await deployContract("ManagerV2Mock");
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    expect(await manager.version()).to.equal(1e6);
    let signature = (
      await signRequest(
        selector,
        bob.address,
        alice.address,
        vault.address,
        tokenId,
        1,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    // set Alice as first Bob's protector
    await manager.connect(bob).setProtector(alice.address, true, ts, 3600, signature);

    expect(await manager.hasProtectors()).to.equal(true);

    await expect(manager.upgrade(managerV2Impl.address)).to.be.revertedWith("NotTheTokenOwner");

    await expect(manager.connect(bob).upgrade(managerV2Impl.address)).to.be.revertedWith("UntrustedImplementation");
    await trustImplementation(
      guardian,
      proposer,
      executor,
      delay,
      bytes4(keccak256("CrunaManager")),
      managerV2Impl.address,
      true,
      1,
    );

    await manager.connect(bob).upgrade(managerV2Impl.address);

    expect(await manager.version()).to.equal(1e6 + 2e3);
    expect(await manager.hasProtectors()).to.equal(true);

    const managerV2 = await ethers.getContractAt("ManagerV2Mock", managerAddress);
    const b4 = "0xaabbccdd";
    expect(await managerV2.bytes4ToHexString(b4)).equal(b4);
  });

  it("should allow deployer to upgrade the default manager", async function () {
    let tokenId = await buyAVault(bob);
    const managerV2Impl = await deployContract("ManagerV2Mock");
    const proxyV2 = await deployContract("ManagerProxyV2Mock", managerV2Impl.address);
    expect(await proxyV2.getImplementation()).to.equal(managerV2Impl.address);
    let history = await vault.managerHistory(0);
    const initialManager = await ethers.getContractAt("CrunaManager", history.managerAddress);
    expect(await initialManager.version()).to.equal(1e6);

    await expect(vault.upgradeDefaultManager(proxyV2.address)).to.be.revertedWith("UntrustedImplementation");

    await trustImplementation(
      guardian,
      proposer,
      executor,
      delay,
      bytes4(keccak256("CrunaManager")),
      managerV2Impl.address,
      true,
      1,
    );

    await expect(vault.upgradeDefaultManager(proxyV2.address))
      .to.emit(vault, "DefaultManagerUpgrade")
      .withArgs(proxyV2.address);

    let secondTokenId = await buyAVault(bob, proxyV2);
    history = await vault.managerHistory(1);
    const newManagerAddress = await vault.defaultManagerImplementation(secondTokenId);
    const newManager = await ethers.getContractAt("CrunaManager", newManagerAddress);

    expect(await newManager.version()).to.equal(1e6 + 2e3);

    const oldManagerAddress = await vault.defaultManagerImplementation(tokenId);
    const oldManager = await ethers.getContractAt("CrunaManager", oldManagerAddress);

    expect(await oldManager.version()).to.equal(1e6);
  });
});
