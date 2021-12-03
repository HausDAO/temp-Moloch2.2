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


describe("Moloch Summoner", function () {
  beforeEach(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

    const Moloch = await hre.ethers.getContractFactory("Moloch");
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

      const sum = await molochSummoner.summonMoloch(
        owner.address,
        [wrapper.address],
        60,
        1,
        1,
        0,
        3,
        0,
        yeeter.address
      );
      const idx = await molochSummoner.daoIdx();
      console.log("idx daoIdx", idx);
      const newMoloch = await molochSummoner.daos(idx);
      console.log("sum...", newMoloch);
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

      const params = {
        to: yeeter.address,
        value: ethers.utils.parseUnits("9.1", "ether").toHexString(),
      };
      const stx = await owner.sendTransaction(params);
      const summonerDeposit = await yeeter.deposits(owner.address);
      console.log("summonerDeposit", summonerDeposit.toString());

      // const mol = await Mol.attach('0xd8058efe0198ae9dd7d563e1b4938dcbc86a1f81');
      // let mem = await mol.members('0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266')

      // unit is 1 so should have returned the .1 and 1 should be left
      expect(summonerDeposit.toString()).to.equal(
        ethers.utils.parseUnits("9", "ether")
      );

      // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

      // // wait until the transaction is mined
      // await setGreetingTx.wait();

      // expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
  });
});
