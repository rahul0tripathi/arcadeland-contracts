import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { ethers } from "hardhat";
import web3 from "web3";
import {
  ArcadeLand,
  ArcadeLand__factory,
  Land,
  Land__factory,
} from "../typechain";

describe("ArcadeLand", function () {
  let owner: SignerWithAddress,
    renter: SignerWithAddress,
    randomAddr: SignerWithAddress;
  let ArcadeLandFactory: ArcadeLand__factory;
  let landMinter: ArcadeLand;
  let RentedLandsFactory: Land__factory;
  let land: Land;
  before(async () => {
    ArcadeLandFactory = await ethers.getContractFactory("ArcadeLand");
    [owner, renter, randomAddr] = await ethers.getSigners();
    landMinter = await ArcadeLandFactory.deploy(
      web3.utils.toBN(10).toString(),
      web3.utils.toWei("0.001", "ether"),
      web3.utils.toWei("0.001", "ether")
    );
    await landMinter.deployed();
  });
  it("should get appropriate values of default states", async function () {
    expect(await landMinter.NAME()).to.equal("arcland");
    expect(await landMinter.SYMBOL()).to.equal("ARC");
  });

  it("Should mint land to owner and check deployed land contract", async function () {
    console.log(`miniting for user ${owner.address}`);
    const mintTxn = await landMinter.connect(owner).mint("https://google.com", {
      value: web3.utils.toWei("0.001", "ether"),
    });
    await mintTxn.wait();
    const bal = await landMinter.balanceOf(owner.address);
    expect(bal).to.eq(web3.utils.toBN(1).toString());
    const NFTOwner = await landMinter.ownerOf(1);
    expect(NFTOwner).to.eq(owner.address);
    console.log(await landMinter.tokenURI(1));
    const contractAddr = await landMinter.lands(1);
    expect(contractAddr).to.not.eq(
      "0x0000000000000000000000000000000000000000"
    );

    RentedLandsFactory = await ethers.getContractFactory("Land");
    land = await RentedLandsFactory.attach(contractAddr);
    expect(await land.getRentedLands()).to.length(0);
    expect(await land.pendingProposal()).to.eq(web3.utils.toBN(0).toString());
  });

  it("Should add a proposal to the land contract", async function () {
    const newProposalTxn = await land
      .connect(renter)
      .newProposal(
        web3.utils.toBN(40).toString(),
        web3.utils.toBN(40).toString(),
        web3.utils.toBN(4).toString(),
        web3.utils.toBN(4).toString(),
        web3.utils.toBN(30).toString(),
        web3.utils.toBN(1223).toString(),
        randomAddr.address,
        {
          value: web3.utils.toWei("0.001", "ether"),
        }
      );
    await newProposalTxn.wait();

    const pending = await land.pendingProposal();
    expect(pending).to.eq(web3.utils.toBN(1).toString());
    const pendingProposal = await land._rents(pending);
    //  console.log(pendingProposal);
  });

  it("approve the current proposal", async function () {
    const newApprovalTxn = await land.connect(owner).updateProposalStatus(true);
    await newApprovalTxn.wait();
    expect(await land.pendingProposal()).equal(web3.utils.toBN(0).toString());
    const rentedLand = await land.getRentedLands();
    expect(await land._tileOwners(web3.utils.toBN(4040).toString())).equal(
      web3.utils.toBN(1).toString()
    );
  });
  it("Should conflict existing assetMap", async () => {
    await expect(
      land
        .connect(renter)
        .newProposal(
          web3.utils.toBN(41).toString(),
          web3.utils.toBN(42).toString(),
          web3.utils.toBN(4).toString(),
          web3.utils.toBN(4).toString(),
          web3.utils.toBN(30).toString(),
          web3.utils.toBN(1223).toString(),
          randomAddr.address,
          {
            value: web3.utils.toWei("0.001", "ether"),
          }
        )
    ).to.be.revertedWith("proposal collision detected");
  });
  it("Should not conflict existing assetMap", async () => {
    await expect(
      land
        .connect(renter)
        .newProposal(
          web3.utils.toBN(55).toString(),
          web3.utils.toBN(55).toString(),
          web3.utils.toBN(4).toString(),
          web3.utils.toBN(4).toString(),
          web3.utils.toBN(30).toString(),
          web3.utils.toBN(1223).toString(),
          randomAddr.address,
          {
            value: web3.utils.toWei("0.001", "ether"),
          }
        )
    ).to.not.be.revertedWith("proposal collision detected");
  });
});
