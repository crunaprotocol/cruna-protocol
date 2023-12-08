const { expect } = require("chai");
const { ethers } = require("hardhat");
const DeployUtils = require("../scripts/lib/DeployUtils");
let deployUtils;
const helpers = require("./helpers");
const { getTimestamp } = require("./helpers");
const { domainType } = require("./helpers/eip712");
helpers.initEthers(ethers);
const { privateKeyByWallet, deployContract, getChainId, makeSignature, keccak256 } = helpers;

describe("SignatureValidator", function () {
  deployUtils = new DeployUtils(ethers);

  let chainId;

  let validator;
  let mailTo;
  let wallet;
  let protector;
  const name = "Cruna";
  const version = "1";

  before(async function () {
    [mailTo, wallet, tokenOwner, protector] = await ethers.getSigners();
    chainId = await getChainId();
  });

  beforeEach(async function () {
    validator = await deployContract("SignatureValidator", name, version);
  });

  it("should recover the signer of a recoverSetActorSigner", async function () {
    const sentinelBytes = ethers.utils.toUtf8Bytes("SENTINEL");
    const scope = ethers.utils.keccak256(sentinelBytes);

    const message = {
      scope: scope.toString(),
      owner: tokenOwner.address,
      actor: protector.address,
      tokenId: 1,
      extraValue: 1,
      timestamp: 1700453731,
      validFor: 3600,
    };

    const signature = await makeSignature(
      chainId,
      validator.address,
      privateKeyByWallet[protector.address],
      "Auth",
      [
        { name: "scope", type: "bytes32" },
        { name: "owner", type: "address" },
        { name: "actor", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "extraValue", type: "uint256" },
        { name: "timestamp", type: "uint256" },
        { name: "validFor", type: "uint256" },
      ],
      message,
    );

    expect(
      await validator.recoverSetActorSigner(
        message.scope,
        message.owner,
        message.actor,
        message.tokenId,
        message.extraValue,
        message.timestamp,
        message.validFor,
        signature,
      ),
    ).equal(protector.address);
  });
});
