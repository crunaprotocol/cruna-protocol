const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

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
} = require("./helpers");

describe("Manager : Safe Recipients", function () {
  let crunaRegistry, proxy, managerImpl, guardian;
  let vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto;
  let chainId, ts;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto] = await ethers.getSigners();

    chainId = await getChainId();
  });

  beforeEach(async function () {
    crunaRegistry = await deployContract("CrunaRegistry");
    managerImpl = await deployContract("Manager");
    guardian = await deployContract("Guardian", deployer.address);
    proxy = await deployContract("ManagerProxy", managerImpl.address);

    vault = await deployContract("CrunaFlexiVault", deployer.address);
    await vault.init(crunaRegistry.address, guardian.address, proxy.address);
    factory = await deployContractUpgradeable("VaultFactory", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin");
    usdt = await deployContract("TetherUSD");

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
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1, true);
    return nextTokenId;
  };

  it("should set up safe recipients", async function () {
    // cl(true)
    const tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    // set Alice and Fred as a safe recipient
    await expect(manager.connect(bob).setSafeRecipient(alice.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, alice.address, true);
    await expect(manager.connect(bob).setSafeRecipient(fred.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, fred.address, true);

    expect(await manager.getSafeRecipients()).deep.equal([alice.address, fred.address]);

    await expect(manager.connect(bob).setSafeRecipient(alice.address, false, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, alice.address, false);

    let signature = (
      await signRequest(
        "Manager",
        "PROTECTOR",
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

    // Set Mark as a safe recipient
    signature = (
      await signRequest(
        "Manager",
        "SAFE_RECIPIENT",
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
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, mark.address, true);

    expect(await vault.isTransferable(tokenId, bob.address, mark.address)).to.be.true;

    // // remove Fred as a safe recipient
    signature = (
      await signRequest(
        "Manager",
        "SAFE_RECIPIENT",
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
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, fred.address, false);
  });
});
