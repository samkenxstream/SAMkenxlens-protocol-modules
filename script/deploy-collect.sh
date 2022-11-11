source .env

set -e

# if [[ $1 == "" || $2 == "" ]]
if [[ $1 == "" ]]
    then
        echo "Usage:"
        echo "  deploy-collect.sh [target environment] [contractName]"
        echo "    e.g. target environment (required): mainnet / testnet / sandbox"
        echo "    e.g. contractName (required)"
        echo "Example:"
        echo "  deploy-collect.sh sandbox StepwiseCollectModule"
        exit 1
fi

SAVED_ADDRESS=$(awk -f JSON.awk addresses.json | grep "\[\"$1\",\"$2\"\]" | sed 's/.*"\(.*\)"/\1/')

if [[ $SAVED_ADDRESS != "" ]]
    then
        echo "Found $2 already deployed on $1 at: $SAVED_ADDRESS"
        read -p "Should we redeploy it? (y/n):" CONFIRMATION
        if [[ $CONFIRMATION != "y" && $CONFIRMATION != "Y" ]]
            then
            echo "Deployment cancelled. Execution terminated."
            exit 1
        fi
fi

NETWORK=$(awk -f JSON.awk addresses.json | grep "\[\"$1\",\"network\"\]" | sed -n 's/.*"\(.*\)"/\1/p')
if [[ $NETWORK == "" ]]
    then
        echo "No network found for $1 envirotnment target in addresses.json. Terminating"
        exit 1
fi

CALLDATA=$(cast calldata "run(string)" $1)

forge script script/deploy-collect.s.sol:DeployStepwiseCollect -s $CALLDATA --rpc-url $NETWORK

read -p "Please verify the data and confirm the deployment (y/n):" CONFIRMATION

if [[ $CONFIRMATION == "y" || $CONFIRMATION == "Y" ]]
    then
        echo "Deploying..."

        FORGE_OUTPUT=$(forge script script/deploy-collect.s.sol:DeployStepwiseCollect -s $CALLDATA --rpc-url $NETWORK --broadcast)
        echo "$FORGE_OUTPUT"

        DEPLOYED_ADDRESS=$(echo "$FORGE_OUTPUT" | grep "Contract Address:" | sed -n 's/.*: \(0x[0-9a-hA-H]\{40\}\)/\1/p')

        if [[ $DEPLOYED_ADDRESS == "" ]]
            then
                echo "Cannot find Deployed address of $2 in foundry logs. Terminating"
                exit 1
        fi

        node saveAddress.js $1 $2 $DEPLOYED_ADDRESS
    else
        echo "Deployment cancelled. Execution terminated."
fi
