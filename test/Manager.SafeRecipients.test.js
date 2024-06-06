const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
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
  selectorId,
  bytes4,
  keccak256,

  deployCanonical,
  setFakeCanonicalIfCoverage,
} = require("./helpers");

describe("CrunaManager : Safe Recipients", function () {
  let crunaRegistry, proxy, managerImpl, guardian, erc6551Registry;

  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto, proposer, executor;
  let chainId, ts;
  const delay = 10;
  let CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN;

  before(async function () {
    [deployer, proposer, executor, bob, alice, fred, mark, otto] = await ethers.getSigners();
    chainId = await getChainId();
    [CRUNA_REGISTRY, ERC6551_REGISTRY, CRUNA_GUARDIAN] = await deployCanonical(deployer, proposer, executor, delay);
    crunaRegistry = await ethers.getContractAt("ERC7656Registry", CRUNA_REGISTRY);
    guardian = await ethers.getContractAt("CrunaGuardian", CRUNA_GUARDIAN);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", ERC6551_REGISTRY);
  });

  beforeEach(async function () {
    managerImpl = await deployContract("CrunaManager");
    proxy = await deployContract("CrunaManagerProxy", managerImpl.address);
    proxy = await deployUtils.attach("CrunaManager", proxy.address);

    vault = await deployContract("OwnableNFT", deployer.address);

    await vault.init(proxy.address, true, 1, 0);
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

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address);
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = (await vault.nftConf()).nextTokenId;
    await factory.connect(bob).buyVaultsAndActivateThem(usdc.address, 1);

    const managerAddress = await vault.managerOf(nextTokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    return nextTokenId;
  };

  it("should set up safe recipients", async function () {
    // cl(true)
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("CrunaManager", managerAddress);

    // set Alice and Fred as a safe recipient
    await expect(manager.connect(bob).setSafeRecipient(alice.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(alice.address, true);
    await expect(manager.connect(bob).setSafeRecipient(fred.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(fred.address, true);

    expect(await manager.getSafeRecipients()).deep.equal([alice.address, fred.address]);

    await expect(manager.connect(bob).setSafeRecipient(alice.address, false, 0, 0, 0))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(alice.address, false);

    let signature = (
      await signRequest(
        await selectorId("ICrunaManager", "setProtector"),
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

    const selector = await selectorId("ICrunaManager", "setSafeRecipient");

    // Set Mark as a safe recipient
    signature = (
      await signRequest(
        selector,
        bob.address,
        mark.address,
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
    await expect(manager.connect(bob).setSafeRecipient(mark.address, true, ts, 3600, signature))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(mark.address, true);

    expect(await manager.isSafeRecipient(mark.address)).to.be.true;

    expect(await vault.isTransferable(tokenId, bob.address, mark.address)).to.be.true;

    // // remove Fred as a safe recipient
    signature = (
      await signRequest(
        selector,
        bob.address,
        fred.address,
        vault.address,
        tokenId,
        0,
        0,
        0,
        ts,
        3600,
        chainId,
        alice.address,
        manager,
      )
    )[0];

    await expect(manager.connect(bob).setSafeRecipient(fred.address, false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    await expect(manager.connect(bob).setSafeRecipient(fred.address, false, ts, 3600, signature))
      .to.emit(manager, "SafeRecipientChange")
      .withArgs(fred.address, false);
  });
});
