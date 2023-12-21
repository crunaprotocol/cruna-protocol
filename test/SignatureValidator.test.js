const { expect } = require("chai");
const { ethers } = require("hardhat");
const helpers = require("./helpers");
const { domainType } = require("./helpers/eip712");

const {
  privateKeyByWallet,
  deployContract,
  getChainId,
  makeSignature,
  keccak256,
  bytes4,
  combineBytes4ToBytes32,
  combineTimestampAndValidFor,
  getTimestamp,
  signRequest,
} = helpers;

describe("SignatureValidator", function () {
  let chainId;

  let validator;
  let deployer, bob, alice, fred, mark, vault;

  before(async function () {
    [deployer, bob, alice, fred, mark, vault] = await ethers.getSigners();
    chainId = await getChainId();
  });

  beforeEach(async function () {
    validator = await deployContract("ValidatorMock");
  });

  it("should recover the signer of a recoverSigner", async function () {
    const nameHash = bytes4(keccak256("Manager"));
    const role = bytes4(keccak256("PROTECTOR"));
    const scope = combineBytes4ToBytes32(nameHash, role);

    const timestamp = (await getTimestamp()).toString();
    const validFor = 3600;
    const timeValidation = combineTimestampAndValidFor(timestamp, validFor);

    const message = {
      scope: scope.toString(),
      owner: alice.address,
      actor: fred.address,
      tokenAddress: vault.address,
      tokenId: 1,
      extra: 1,
      extra2: 0,
      extra3: 0,
      timeValidation: timeValidation.toString(),
    };

    const signature = await makeSignature(
      chainId,
      validator.address,
      privateKeyByWallet[fred.address],
      "Auth",
      [
        { name: "scope", type: "bytes32" },
        { name: "owner", type: "address" },
        { name: "actor", type: "address" },
        { name: "tokenAddress", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "extra", type: "uint256" },
        { name: "extra2", type: "uint256" },
        { name: "extra3", type: "uint256" },
        { name: "timeValidation", type: "uint256" },
      ],
      message,
    );

    expect(
      await validator.recoverSigner(
        message.scope,
        message.owner,
        message.actor,
        message.tokenAddress,
        message.tokenId,
        message.extra,
        message.extra2,
        message.extra3,
        message.timeValidation,
        signature,
      ),
    ).equal(fred.address);
  });

  it("should recover using signRequest helper", async function () {
    const timestamp = (await getTimestamp()).toString();
    const validFor = 3600;

    const [signature, message] = await signRequest(
      "Manager",
      "PROTECTOR",
      alice.address,
      fred.address,
      vault.address,
      1,
      1,
      0,
      0,
      timestamp,
      validFor,
      chainId,
      bob.address,
      validator,
    );

    expect(
      await validator.recoverSigner(
        message.scope,
        message.owner,
        message.actor,
        message.tokenAddress,
        message.tokenId,
        message.extra,
        message.extra2,
        message.extra3,
        message.timeValidation,
        signature,
      ),
    ).equal(bob.address);
  });
});
