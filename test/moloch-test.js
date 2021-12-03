const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let addr1;
let addr2;
let addrs;

let yeeter;
let wrapper;
let moloch;
let molochSummoner;
let Moloch;

describe("Moloch Summoner", function () {
  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    Moloch = await hre.ethers.getContractFactory("Moloch");
    const MolochSummoner = await hre.ethers.getContractFactory(
      "MolochSummoner"
    );
    const Yeeter = await hre.ethers.getContractFactory("Yeeter");
    const Wrapper = await hre.ethers.getContractFactory("Wrapper");

    yeeter = await Yeeter.deploy();
    await yeeter.deployed();
    console.log("Yeeter deployed to:", yeeter.address);

    wrapper = await Wrapper.deploy();
    await wrapper.deployed();
    console.log("Wrapper deployed to:", wrapper.address);

    moloch = await Moloch.deploy();
    await moloch.deployed();
    console.log("Moloch Template deployed to:", moloch.address);

    molochSummoner = await MolochSummoner.deploy(moloch.address);
    await molochSummoner.deployed();
    console.log("MolochSummoner deployed to:", molochSummoner.address);
    console.log("owner.address", owner.address);
  });
  describe("Deployment", function () {
    it("Should summon a dao and yeeter, take deposits in units", async function () {
      const [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

      console.log("MolochSummoner deployed to:", molochSummoner.address);
      console.log("owner.address", owner.address);
      /* Summon new dao 
      Summoner will have one share
      */
      const sum = await molochSummoner.summonMoloch(
        owner.address,
        [wrapper.address],
        60,
        1,
        1,
        0,
        3,
        0
      );
      const idx = await molochSummoner.daoIdx();
      console.log("idx daoIdx", idx.toString());
      const newMoloch = await molochSummoner.daos(idx);
      console.log("sum...", newMoloch);

      const mol = await Moloch.attach(newMoloch);
      let mem = await mol.members(owner.address);
      expect(mem.shares.toString()).to.equal("1");
      console.log("owner shares", mem.shares.toString());
      /* Summoner can make a function call to set more summoners and to set the shaman
      this currently could be run multiple times if the summoner does not set a shaman the first time
      should force this to be one time only
      shaman could be set to a yeeter or a minion
       */
      const multiSummon = await mol.multiSummon(
        yeeter.address,
        [owner.address, addr1.address, addr2.address],
        ["9", "10", "10"]
      );
      mem = await mol.members(owner.address);
      expect(mem.shares.toString()).to.equal("10");

      /* Configure the shaman(yeeter) that was added to the moloch
       */
      const inityeet = await yeeter.init(
        newMoloch,
        wrapper.address,
        ethers.utils.parseUnits("100", "ether"),
        "1622898000000",
        "0",
        "10",
        ethers.utils.parseUnits("1", "ether"),
        "200"
      );

      /* Send funds to the yeeter which will update the loot
       */
      const params = {
        to: yeeter.address,
        value: ethers.utils.parseUnits("9.1", "ether").toHexString(),
      };
      const stx = await owner.sendTransaction(params);
      const summonerDeposit = await yeeter.deposits(owner.address);
      console.log("summonerDeposit", summonerDeposit.toString());
      // unitPrice is 1 so should have returned the .1 and 9 should be left
      expect(summonerDeposit.toString()).to.equal(
        ethers.utils.parseUnits("9", "ether")
      );
    });
  });
});
