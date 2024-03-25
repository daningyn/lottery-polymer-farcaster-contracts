# Install dependencies
install:
    echo "Installing dependencies"
    npm install
    forge install --shallow

# Compile contracts using the specified compiler or default to Hardhat
# The compiler argument is optional; if not provided, it defaults to "hardhat".
# Usage: just compile [compiler]
compile COMPILER='hardhat':
    #!/usr/bin/env sh
    if test "{{COMPILER}}" = "hardhat"; then
        echo "Compiling contracts with Hardhat..."
        npx hardhat compile
    elif test "{{COMPILER}}" = "foundry"; then
        echo "Compiling contracts with Foundry..."
        forge build
    else
        echo "Unknown compiler: {{COMPILER}}"
        exit 1
    fi

# Update the config.json file with the contract type for a specified chain/rollup
# The chain and contract-type arguments are REQUIRED;
# The universal argument is optional; if not provided, it defaults to "true".
# It indicates whether the contracts to deploy are using custom or universal IBC channels to send packets.
# Usage: just set-contracts [chain] [contract-type] [universal]
set-contracts CHAIN CONTRACT_TYPE UNIVERSAL='true':
    echo "Updating config.json with contract type..."
    node scripts/private/_set-contracts-config.js {{CHAIN}} {{CONTRACT_TYPE}} {{UNIVERSAL}}

# Deploy the contracts in the /contracts folder using Hardhat and updating the config.json file
# The source and destination arguments are REQUIRED;
# Usage: just deploy [source] [destination]
deploy SOURCE DESTINATION:
        echo "Deploying contracts with Hardhat..."
        node scripts/private/_deploy-config.js {{SOURCE}} {{DESTINATION}}

# Run the sanity check script to verify that configuration (.env) files match with deployed contracts' stored values
# Usage: just sanity-check
sanity-check:
    echo "Running sanity check..."
    node scripts/private/_sanity-check.js

lottery-deploy:
    echo "Deploying lottery contracts..."
    just deploy optimism base
    just sanity-check

lottery-create-channel:
    echo "Creating lottery channel..."
    node scripts/private/_create-lottery-channel-config.js

lottery-start-game numOfChallenges challengeDuration:
    echo "Starting lottery game..."
    node scripts/private/_start-lottery-game.js {{numOfChallenges}} {{challengeDuration}}

lottery-buy-ticket FROM TICKET_NUMBER:
    echo "Buying lottery tickets..."
    node scripts/private/_send-packet-ticket-config.js {{FROM}} {{TICKET_NUMBER}}

lottery-demo:
    echo "Running lottery demo..."
    just lottery-deploy
    just lottery-create-channel
    just lottery-start-game 4 60
    just lottery-buy-ticket optimism 30

# Clean up the environment by removing the artifacts and cache folders and running the forge clean command
# Usage: just clean
clean:
    echo "Cleaning up environment..."
    rm -rf artifacts cache
    forge clean

# Fully clean the environment by removing the artifacts, the dependencies, and cache folders and running the forge clean-all command
# Usage: just clean-all
clean-all:
    echo "Cleaning up environment..."
    rm -rf artifacts cache
    forge clean
    rm -rf node_modules
