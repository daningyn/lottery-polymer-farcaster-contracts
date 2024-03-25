const { exec } = require("child_process");
const {getConfigPath, getWhitelistedNetworks} = require('./_helpers.js');
const { setupIbcPacketEventListener } = require('./_events.js');

const mainChain = 'base';

const numOfChallenges = process.argv[2];
const challengeDuration = process.argv[3];
if (!numOfChallenges || !challengeDuration) {
  console.error('Usage: just lottery-start-game <numOfChallenges> <challengeDuration>');
  process.exit(1);
}

function runSendPacketCommand(command) {
  return new Promise((resolve, reject) => {
    exec(command, (error, stdout, stderr) => {
      if (error) {
        console.error(`exec error: ${error}`);
        reject(error);
      } else {
        console.log(stdout);
        resolve(true);
      }
    });
  });
}

async function runSendPacket(config) {
  const script = 'start-game.js';
  const command = `numOfChallenges=${numOfChallenges} challengeDuration=${challengeDuration}  npx hardhat run scripts/${script} --network ${mainChain}`;

  try {
    await runSendPacketCommand(command);
  } catch (error) {
    console.error("❌ Error starting game: ", error);
    process.exit(1);
  }
}

async function main() {
  const configPath = getConfigPath();
  const config = require(configPath);

  await runSendPacket(config);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});