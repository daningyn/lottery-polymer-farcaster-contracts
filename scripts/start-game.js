const hre = require('hardhat');
const { getConfigPath } = require('./private/_helpers');
const { getIbcApp } = require('./private/_vibc-helpers.js');

const numOfChallenges = process.env.numOfChallenges;
const challengeDuration = process.env.challengeDuration;

if (!numOfChallenges || !challengeDuration) {
  console.error('Usage: just lottery-start-game <numOfChallenges> <challengeDuration>');
  process.exit(1);
}

async function main() {
    const accounts = await hre.ethers.getSigners();
    const config = require(getConfigPath());

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);
    
    // Send the packet
    await ibcApp.connect(accounts[0]).startNewGame(
      numOfChallenges,
      challengeDuration
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});