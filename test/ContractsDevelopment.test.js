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
} = require("./helpers");

describe("Testing contract deployments", function () {
  let crunaRegistry, proxy, managerImpl, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor, proposer2, executor2;
  let chainId, ts;
  const delay = 10;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto, proposer, executor, proposer2, executor2] = await ethers.getSigners();

    chainId = await getChainId();
  });

  beforeEach(async function () {
    crunaRegistry = await deployContract("CrunaRegistry");
    managerImpl = await deployContract("CrunaManager");
    guardian = await deployContract("CrunaGuardian", delay, [proposer.address], [executor.address], deployer.address);
    expect(await guardian.version()).to.equal(1000000);
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);
    // sent 2 ETH to proxy
    await expect(
      deployer.sendTransaction({ to: proxy.address, value: amount("2"), gasLimit: ethers.utils.hexlify(100000) }),
    ).revertedWith("ERC1967NonPayable");

    vault = await deployContract("CrunaVaults", delay, [proposer.address], [executor.address], deployer.address);
    expect(await vault.version()).to.equal(1000000);
    await vault.init(crunaRegistry.address, guardian.address, proxy.address);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address, deployer.address]);
    await vault.setFactory(factory.address);
    expect(await vault.supportsInterface(getInterfaceId("IAccessControl"))).to.equal(true);

    expect(await vault.maxTokenId()).to.equal(0);
    // first time it does not require a proposer/executor approach
    await vault.setMaxTokenId(10000);
    expect(await vault.maxTokenId()).to.equal(10000);

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
    expect(await vault.maxTokenId()).to.equal(20000);
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
    await factory.connect(bob).buyVaults(usdc.address, 1);
    expect(await ethers.provider.getCode(managerAddress)).not.equal("0x");
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);
    expect(await manager.tokenId()).to.equal(nextTokenId);
    expect(await manager.vault()).to.equal(vault.address);
    expect(await manager.owner()).to.equal(bob.address);
  });

  it("should update the parameters", async function () {
    expect(await vault.totalProposers()).to.equal(1);
    await expect(proposeAndExecute(vault, proposer, executor, 10, "addProposer", proposer2.address))
      .to.emit(vault, "RoleGranted")
      .withArgs(await vault.PROPOSER_ROLE(), proposer2.address, vault.address);
    expect(await vault.totalProposers()).to.equal(2);
    expect(await vault.totalExecutors()).to.equal(1);
    await expect(proposeAndExecute(vault, proposer, executor, 10, "addExecutor", executor2.address))
      .to.emit(vault, "RoleGranted")
      .withArgs(await vault.EXECUTOR_ROLE(), executor2.address, vault.address);
    expect(await vault.totalExecutors()).to.equal(2);
    await expect(proposeAndExecute(vault, proposer2, executor, 10, "removeProposer", proposer.address))
      .to.emit(vault, "RoleRevoked")
      .withArgs(await vault.PROPOSER_ROLE(), proposer.address, vault.address);
    expect(await vault.totalProposers()).to.equal(1);
    await expect(proposeAndExecute(vault, proposer2, executor2, 10, "removeExecutor", executor.address))
      .to.emit(vault, "RoleRevoked")
      .withArgs(await vault.EXECUTOR_ROLE(), executor.address, vault.address);
    expect(await vault.totalExecutors()).to.equal(1);
  });
});
