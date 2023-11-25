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

describe("Integration", function () {
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

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true)).to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
    ts = (await getTimestamp()) - 100;
  });

  const buyAVault = async (bob) => {
    const price = await factory.finalPrice(usdc.address, "");
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    await factory.connect(bob).buyVaults(usdc.address, 1, "");
    return nextTokenId;
  };

  it("should deploy everything as expected", async function () {
    // test the beforeEach
  });

  it("should get the token parameters from the manager", async function () {
    let price = await factory.finalPrice(usdc.address, "");
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const managerAddress = await vault.managerOf(nextTokenId);
    expect(await ethers.provider.getCode(managerAddress)).equal("0x");
    await factory.connect(bob).buyVaults(usdc.address, 1, "");
    expect(await ethers.provider.getCode(managerAddress)).not.equal("0x");
    const manager = await ethers.getContractAt("Manager", managerAddress);
    expect(await manager.vault()).to.equal(vault.address);
    expect(await manager.tokenId()).to.equal(nextTokenId);
    expect(await manager.owner()).to.equal(bob.address);
  });

  describe("Protectors management", async function () {
    it("should add the first protector", async function () {
      let tokenId = await buyAVault(bob);
      const managerAddress = await vault.managerOf(tokenId);
      const manager = await ethers.getContractAt("Manager", managerAddress);
      // set Alice as first Bob's protector
      await expect(manager.connect(bob).setProtector(alice.address, true, 0, 0, 0))
        .to.emit(manager, "ProtectorUpdated")
        .withArgs(bob.address, alice.address, true);
    });

    it("should throw is wrong data for first protector", async function () {
      let tokenId = await buyAVault(bob);
      const managerAddress = await vault.managerOf(tokenId);
      const manager = await ethers.getContractAt("Manager", managerAddress);
      // set Alice as first Bob's protector
      await expect(manager.connect(bob).setProtector(addr0, true, 0, 0, 0)).revertedWith("ZeroAddress");
      await expect(manager.connect(bob).setProtector(bob.address, true, 0, 0, 0)).revertedWith("CannotBeYourself");
    });

    it("should add many protectors", async function () {
      let tokenId = await buyAVault(bob);
      const managerAddress = await vault.managerOf(tokenId);
      const manager = await ethers.getContractAt("Manager", managerAddress);

      // set Alice as first Bob's protector
      await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
      // Set Fred as Bob's protector
      // To do so Bob needs Alice's signature

      let allProtectors = await manager.getProtectors();
      expect(allProtectors[0]).equal(alice.address);

      let signature = await signRequest(
        "PROTECTOR",
        bob.address,
        fred.address,
        tokenId,
        true,
        ts,
        3600,
        chainId,
        alice.address,
        signatureValidator,
      );
      await expect(manager.connect(bob).setProtector(fred.address, true, ts, 3600, signature))
        .to.emit(manager, "ProtectorUpdated")
        .withArgs(bob.address, fred.address, true);

      allProtectors = await manager.getProtectors();
      expect(allProtectors[1]).equal(fred.address);

      // let Fred remove Alice as protector
      signature = await signRequest(
        "PROTECTOR",
        bob.address,
        alice.address,
        tokenId,
        false,
        ts,
        3600,
        chainId,
        fred.address,
        signatureValidator,
      );
      await expect(manager.connect(bob).setProtector(alice.address, false, ts, 3600, signature))
        .to.emit(manager, "ProtectorUpdated")
        .withArgs(bob.address, alice.address, false);
    });

    it("should add a protector and transfer a vault", async function () {
      let tokenId = await buyAVault(bob);
      const managerAddress = await vault.managerOf(tokenId);
      const manager = await ethers.getContractAt("Manager", managerAddress);
      // set Alice as Bob's protector
      await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
      await expect(
        vault.connect(bob)["safeTransferFrom(address,address,uint256)"](bob.address, fred.address, tokenId),
      ).to.be.revertedWith("NotTransferable");
      let signature = await signRequest(
        "PROTECTED_TRANSFER",
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
      await expect(vault.connect(bob).protectedTransfer(tokenId, fred.address, ts, 3600, signature))
        .to.emit(vault, "Transfer")
        .withArgs(bob.address, fred.address, tokenId);
    });
  });

  describe("Safe recipients", async function () {
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

  describe("Sentinels and beneficiary", async function () {
    it("should set up sentinel", async function () {
      let tokenId = await buyAVault(bob);
      const managerAddress = await vault.managerOf(tokenId);
      const manager = await ethers.getContractAt("Manager", managerAddress);
      await expect(manager.connect(bob).setSentinel(alice.address, true, 0, 0, 0))
        .to.emit(manager, "SentinelUpdated")
        .withArgs(bob.address, alice.address, true);
      await expect(manager.connect(bob).setSentinel(fred.address, true, 0, 0, 0))
        .to.emit(manager, "SentinelUpdated")
        .withArgs(bob.address, fred.address, true);
      await expect(manager.connect(bob).setSentinel(alice.address, false, 0, 0, 0))
        .to.emit(manager, "SentinelUpdated")
        .withArgs(bob.address, alice.address, false);
      // set Alice as a protector
      await manager.connect(bob).setProtector(alice.address, true, 0, 0, 0);
      // Set Mark as a safe recipient
      let signature = await signRequest(
        "SENTINEL",
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
      await expect(manager.connect(bob).setSentinel(mark.address, true, ts, 3600, signature))
        .to.emit(manager, "SentinelUpdated")
        .withArgs(bob.address, mark.address, true);

      // // remove Fred as a safe recipient

      signature = await signRequest(
        "SENTINEL",
        bob.address,
        fred.address,
        tokenId,
        false,
        ts,
        1000,
        chainId,
        alice.address,
        signatureValidator,
      );

      await expect(manager.connect(bob).setSentinel(fred.address, false, ts, 3600, signature)).revertedWith(
        "WrongDataOrNotSignedByProtector",
      );

      signature = await signRequest(
        "SENTINEL",
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

      await expect(manager.connect(bob).setSentinel(fred.address, false, 0, 0, 0)).revertedWith(
        "NotPermittedWhenProtectorsAreActive",
      );

      await expect(manager.connect(bob).setSentinel(fred.address, false, ts, 3600, signature))
        .to.emit(manager, "SentinelUpdated")
        .withArgs(bob.address, fred.address, false);
    });
  });
});
