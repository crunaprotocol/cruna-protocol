const { expect } = require("chai");
const { ethers } = require("hardhat");
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
  signRequest,
  getInterfaceId,
  proposeAndExecute,

  deployCanonical,
  setFakeCanonicalIfCoverage,
  deployNickSFactory,
  deployERC7656Registry,
  getBytecodeForNickSFactory,
} = require("./helpers");

describe("Testing contract deployments", function () {
  let crunaRegistry, proxy, managerImpl, guardian, erc6551Registry;

  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor, proposer2, executor2;
  let chainId, ts;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mark, otto, proposer2, executor2] = await ethers.getSigners();

    chainId = await getChainId();
    [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("ERC7656Registry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);

    let tx = await crunaRegistry.create(guardian.address, ethers.constants.HashZero, 31337, guardian.address, 1001);
    await tx.wait();

    let addr = await crunaRegistry.compute(guardian.address, ethers.constants.HashZero, 31337, guardian.address, 1001);

    let code = await ethers.provider.getCode(addr);
    expect(code !== "0x").to.be.true;

    addr = await crunaRegistry.compute(guardian.address, ethers.constants.HashZero, 31337, guardian.address, 1000);

    code = await ethers.provider.getCode(addr);
    expect(code !== "0x").to.be.false;
  });

  beforeEach(async function () {
    managerImpl = await deployContract("CrunaManager");
    expect(await guardian.version()).to.equal(1003000);
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);
    // sent 2 ETH to proxy
    await expect(
      deployer.sendTransaction({ to: proxy.address, value: amount("2"), gasLimit: ethers.utils.hexlify(100000) }),
    ).revertedWith("ERC1967NonPayable");

    vault = await deployContract("TimeControlledNFT", delay, [proposer.address], [executor.address], deployer.address);

    const registryMock = await deployContract("RegistryMock");

    let computedAddress = await registryMock.compute(managerImpl.address, ethers.constants.HashZero, 31337, vault.address, 1);
    await expect(registryMock.create(managerImpl.address, ethers.constants.HashZero, 31337, vault.address, 1))
      .to.emit(registryMock, "Created")
      .withArgs(computedAddress, managerImpl.address, ethers.constants.HashZero, 31337, vault.address, 1);

    expect(await registryMock.supportsInterface("0xc6bdc908")).to.be.true;

    expect(await vault.version()).to.equal(1000000);
    await vault.init(proxy.address, true, 1, 0);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);
    await vault.setFactory(factory.address);
    expect(await vault.supportsInterface(getInterfaceId("IAccessControl"))).to.equal(true);

    expect((await vault.nftConf()).maxTokenId).to.equal(0);
    // first time it does not require a proposer/executor approach
    await vault.setMaxTokenId(10000);
    expect((await vault.nftConf()).maxTokenId).to.equal(10000);

    usdc = await deployContract("USDCoin", deployer.address);
    usdt = await deployContract("TetherUSD", deployer.address);

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;

    // second time it requires a proposer/executor approach
    await expect(vault.setMaxTokenId(20000)).revertedWith("MustCallThroughTimeController");
    await proposeAndExecute(vault, proposer, executor, 10, "setMaxTokenId", 20000);
    expect((await vault.nftConf()).maxTokenId).to.equal(20000);
  });

  it("should deploy everything as expected", async function () {
    // test the beforeEach
  });

  it("should get the token parameters from the manager", async function () {
    let price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = (await vault.nftConf()).nextTokenId;
    const managerAddress = await vault.managerOf(nextTokenId);
    expect(await ethers.provider.getCode(managerAddress)).equal("0x");
    await factory.connect(bob).buyVaults(usdc.address, 1);
    expect(await ethers.provider.getCode(managerAddress)).not.equal("0x");
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    expect(await manager.tokenId()).to.equal(nextTokenId);
    expect(await manager.vault()).to.equal(vault.address);
    expect(await manager.owner()).to.equal(bob.address);
  });
});
