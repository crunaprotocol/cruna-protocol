const { expect } = require("chai");
const { ethers } = require("hardhat");

let count = 9000;
function cl() {
  console.log(count++);
}

const {
  amount,
  normalize,
  deployContractUpgradeable,
  addr0,
  deployNickSFactory,
  deployContractViaNickSFactory,
  deployContract,
} = require("./helpers");

const registryBytecode = require("../artifacts/erc6551/ERC6551Registry.sol/ERC6551Registry.json").bytecode;
const managerBytecode = require("../artifacts/contracts/manager/Manager.sol/Manager.json").bytecode;

describe("Factory", function () {
  let erc6551RegistryAddress, managerAddress;
  let erc6551Registry, proxy, manager, guardian;
  let signatureValidator, vault;
  let salt;
  let factory;
  let usdc, usdt;
  let deployer, bob, alice, fred;

  before(async function () {
    [deployer, bob, alice, fred] = await ethers.getSigners();
    await deployNickSFactory(deployer);
    salt = "0x0000000000000000000000000000000000000000fd8eb4e1dca713016c518e31";
    erc6551RegistryAddress = await deployContractViaNickSFactory(deployer, registryBytecode, salt);
    erc6551Registry = await ethers.getContractAt("ERC6551Registry", erc6551RegistryAddress);
    expect(erc6551RegistryAddress).to.equal("0xd97C080c191AdcE8Abc9789f520F67f4FE18e0e7");
    managerAddress = await deployContractViaNickSFactory(deployer, managerBytecode, salt);
    manager = await ethers.getContractAt("Manager", managerAddress);
    signatureValidator = await deployContract("SignatureValidator", "Cruna", "1");
  });

  beforeEach(async function () {
    guardian = await deployContract("AccountGuardian", deployer.address);
    proxy = await deployContract("ManagerProxy", guardian.address, managerAddress);
    vault = await deployContract(
      "CrunaFlexiVault",
      erc6551RegistryAddress,
      guardian.address,
      signatureValidator.address,
      managerAddress,
      proxy.address
    );
    factory = await deployContractUpgradeable("VaultFactory", [vault.address]);

    await vault.setFactory(factory.address);

    usdc = await deployContract("USDCoin");
    usdt = await deployContract("TetherUSD");

    await usdc.mint(bob.address, normalize("900"));
    await usdt.mint(alice.address, normalize("600", 6));

    await expect(factory.setPrice(990)).to.emit(factory, "PriceSet").withArgs(990);
    await expect(factory.setStableCoin(usdc.address, true))
        .to.emit(factory, "StableCoinSet").withArgs(usdc.address, true);
    await expect(factory.setStableCoin(usdt.address, true))
        .to.emit(factory, "StableCoinSet").withArgs(usdt.address, true);
  });

  it.only("should get the precalculated address of the manager", async function () {

    const managerAddress = await vault.managerAddress(1);
    //
    // let price = await factory.finalPrice(usdc.address, "");
    // await usdc.connect(bob).approve(factory.address, price);
    // await expect(factory.connect(bob).buyVaults(usdc.address, 1, ""))
    //     .to.emit(vault, "Transfer")
    //     .withArgs(addr0, bob.address, 1)
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

    await expect(factory.withdrawProceeds(fred.address, usdc.address, normalize("10")))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.target, fred.address, normalize("10"));
    await expect(factory.withdrawProceeds(fred.address, usdc.target, 0))
      .to.emit(usdc, "Transfer")
      .withArgs(factory.target, fred.address, amount("9.8"));
  });
});
