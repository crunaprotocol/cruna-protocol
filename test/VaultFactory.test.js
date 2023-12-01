const { expect } = require("chai");
const { ethers } = require("hardhat");
const { toChecksumAddress } = require("ethereumjs-util");
let count = 9000;
function cl() {
  console.log(count++);
}

const {
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  getChainId,
  deployContract,
  getTimestamp,
  keccak256,
} = require("./helpers");

describe("VaultFactory", function () {
  let erc6551Registry, proxy, managerImpl, guardian;
  let signatureValidator, vault;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred;

  before(async function () {
    [deployer, bob, alice, fred] = await ethers.getSigners();
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
  });

  //here we test the contract
  beforeEach(async function () {
    erc6551Registry = await deployContract("ERC6551Registry");
    managerImpl = await deployContract("Manager");
    guardian = await deployContract("Guardian", deployer.address);
    proxy = await deployContract("ManagerProxy", managerImpl.address);

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

  it("should get the precalculated address of the manager", async function () {
    let price = await factory.finalPrice(usdc.address, "");
    await usdc.connect(bob).approve(factory.address, price);
    const nextTokenId = await vault.nextTokenId();
    const precalculatedAddress = await vault.managerOf(nextTokenId);
    const salt = ethers.utils.hexZeroPad(ethers.BigNumber.from("400").toHexString(), 32);

    await expect(factory.connect(bob).buyVaults(usdc.address, 1, ""))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, bob.address, nextTokenId)
      .to.emit(erc6551Registry, "ERC6551AccountCreated")
      .withArgs(
        precalculatedAddress,
        toChecksumAddress(proxy.address),
        salt,
        (await getChainId()).toString(),
        toChecksumAddress(vault.address),
        nextTokenId,
      );
  });

  async function buyVault(token, amount, buyer, promoCode = "") {
    let price = await factory.finalPrice(token.address, promoCode);
    await token.connect(buyer).approve(factory.address, price.mul(amount));

    await expect(factory.connect(buyer).buyVaults(token.address, amount, promoCode))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, buyer.address, 1)
      .to.emit(vault, "Transfer")
      .withArgs(addr0, buyer.address, 2)
      .to.emit(token, "Transfer")
      .withArgs(buyer.address, factory.address, price.mul(amount));
  }

  it("should allow bob and alice to purchase some vaults", async function () {
    await buyVault(usdc, 2, bob);
    await buyVault(usdt, 2, alice);

    let price = await factory.finalPrice(usdc.address, "");
    expect(price.toString()).to.equal("9900000000000000000");
    price = await factory.finalPrice(usdt.address, "");
    expect(price.toString()).to.equal("9900000");

    await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, normalize("10"));
    await expect(factory.withdrawProceeds(fred.address, usdc.address, 0))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.address, fred.address, amount("9.8"));
  });

  it("should allow bob and alice to purchase some vaults with a promoCode", async function () {
    const promoCode = "TheRoundTable".toLowerCase();
    await factory.setPromoCode(promoCode, 10);

    await buyVault(usdc, 2, bob);
    await buyVault(usdt, 2, alice, promoCode);

    let price = await factory.finalPrice(usdc.address, "");
    expect(price.toString()).to.equal("9900000000000000000");
    price = await factory.finalPrice(usdt.address, promoCode);
    expect(price.toString()).to.equal("8910000");
  });

  it("should remove a stableCoin when active is false", async function () {
    await expect(factory.setStableCoin(usdc.address, false)).to.emit(factory, "StableCoinSet").withArgs(usdc.address, false);

    const updatedStableCoins = await factory.getStableCoins();
    expect(updatedStableCoins).to.not.include(usdc.address);
  });

  it("should remove the effect of a promo code when its discount is set to zero", async function () {
    const promoCode = "TheRoundTable".toLowerCase();
    const discount = 10;
    const zeroDiscount = 0;
    const stableCoin = usdc.address;

    await factory.setPromoCode(promoCode, discount);

    await factory.setPromoCode(promoCode, zeroDiscount);
    let priceAfterDiscountReset = await factory.finalPrice(stableCoin, promoCode);

    let regularPrice = await factory.finalPrice(stableCoin, "");
    expect(priceAfterDiscountReset).to.equal(regularPrice);
  });

  it("should allow batch purchase of vaults", async function () {
    const stableCoin = usdc.address;
    const buyers = [bob.address];
    const amounts = [1];

    let pricePerVault = await factory.finalPrice(stableCoin, "");
    let totalPayment = pricePerVault.mul(amounts.length);

    await usdc.mint(bob.address, totalPayment.add(normalize("1000")));

    await usdc.connect(bob).approve(factory.address, totalPayment);

    await expect(factory.connect(bob).buyVaultsBatch(stableCoin, buyers, amounts, ""))
      .to.emit(vault, "Transfer")
      .withArgs(addr0, buyers[0], (await getChainId()) * 1e6 + 1);

    expect(await usdc.balanceOf(factory.address)).to.equal(totalPayment);

    expect(await vault.balanceOf(bob.address)).to.equal(amounts.length);
  });
});
