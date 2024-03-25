const { exec } = require("child_process");
const {getConfigPath, getWhitelistedNetworks} = require('./_helpers.js');
const { setupIbcPacketEventListener } = require('./_events.js');

const source = process.argv[2];
const ticketNumber = process.argv[3];
if (!source || !ticketNumber) {
  console.error('Usage: just lottery-buy-ticket <FROM> <TICKET_NUMBER>');
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
  // Check if the source chain from user input is whitelisted
  const allowedNetworks = getWhitelistedNetworks();
  if (!allowedNetworks.includes(source)) {
    console.error("❌ Please provide a valid source chain");
    process.exit(1);
  }

  const script = 'choose-number.js';
  const command = `ticketNumber=${ticketNumber} npx hardhat run scripts/${script} --network ${source}`;

  try {
    await setupIbcPacketEventListener();
    await runSendPacketCommand(command);
  } catch (error) {
    console.error("❌ Error sending packet: ", error);
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