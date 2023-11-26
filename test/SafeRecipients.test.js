const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");

let count = 9000;
function cl(...args) {
  console.log(count++, ...args);
}

const {
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  signRequest,
} = require("./helpers");

describe("Protectors", function () {
  let erc6551Registry, proxy, manager, guardian;
  let signatureValidator, vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred, mark, otto;
  let chainId, ts;

  before(async function () {
    [deployer, bob, alice, fred, mark, otto] = await ethers.getSigners();
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
    chainId = await getChainId();
  });

  beforeEach(async function () {
    erc6551Registry = await deployContract("ERC6551Registry");
    manager = await deployContract("Manager");
    guardian = await deployContract("AccountGuardian", deployer.address);
    proxy = await deployContract("ManagerProxy", manager.address);
    vault = await deployContract(
      "CrunaFlexiVault",
      erc6551Registry.address,
      guardian.address,
      signatureValidator.address,
      proxy.address,
    );
    factory = await deployContractUpgradeable("VaultFactory", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin");
    usdt = await deployContract("TetherUSD");

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await factory.setPrice(990);
    await factory.setStableCoin(usdc.address, true);
    await factory.setStableCoin(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address, "");
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1, "");
    return nextTokenId;
  };

  it("should set up safe recipients", async function () {
    // cl(true)
    let tokenId = await buyAVault(bob);
    const managerAddress = await vault.managerOf(tokenId);
    const manager = await ethers.getContractAt("Manager", managerAddress);
    // set Alice and Fred as a safe recipient
    await expect(manager.connect(bob).setSafeRecipient(alice.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, alice.address, true);
    await expect(manager.connect(bob).setSafeRecipient(fred.address, true, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, fred.address, true);
    await expect(manager.connect(bob).setSafeRecipient(alice.address, false, 0, 0, 0))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, alice.address, false);
    // set Alice as a protector
    await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
    // Set Mark as a safe recipient
    let signature = await signRequest(
      "SAFE_RECIPIENT",
      bob.address,
      mark.address,
      tokenId,
      true,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );
    await expect(manager.connect(bob).setSafeRecipient(mark.address, true, ts, 3600, signature))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, mark.address, true);

    // // remove Fred as a safe recipient
    signature = await signRequest(
      "SAFE_RECIPIENT",
      bob.address,
      fred.address,
      tokenId,
      false,
      ts,
      3600,
      chainId,
      alice.address,
      signatureValidator,
    );

    await expect(manager.connect(bob).setSafeRecipient(fred.address, false, 0, 0, 0)).revertedWith(
      "NotPermittedWhenProtectorsAreActive",
    );

    await expect(manager.connect(bob).setSafeRecipient(fred.address, false, ts, 3600, signature))
      .to.emit(manager, "SafeRecipientUpdated")
      .withArgs(bob.address, fred.address, false);
  });
});
