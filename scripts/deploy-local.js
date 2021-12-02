// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Moloch = await hre.ethers.getContractFactory("Moloch");
  const MolochSummoner = await hre.ethers.getContractFactory("MolochSummoner");
  const Yeeter = await hre.ethers.getContractFactory("Yeeter");
  const Wrapper = await hre.ethers.getContractFactory("Wrapper");
  
  const yeeter = await Yeeter.deploy();

  await yeeter.deployed();

  console.log("Yeeter deployed to:", yeeter.address);

  const wrapper = await Wrapper.deploy();

  await wrapper.deployed();
  console.log("Wrapper deployed to:", wrapper.address);

  const moloch = await Moloch.deploy();

  await moloch.deployed();

  console.log("Moloch Template deployed to:", moloch.address);

  const molochSummoner = await MolochSummoner.deploy(moloch.address);

  await molochSummoner.deployed();

  console.log("MolochSummoner deployed to:", molochSummoner.address);

  // const box = await MolochSummoner.attach(molochSummoner.address);
  // let newMoloch = await box.summonMoloch()
  // address _summoner,
  // address[] memory _approvedTokens,
  // uint256 _periodDuration,
  // uint256 _votingPeriodLength,
  // uint256 _gracePeriodLength,
  // uint256 _proposalDeposit,
  // uint256 _dilutionBound,
  // uint256 _processingReward,
  // address _shaman
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
