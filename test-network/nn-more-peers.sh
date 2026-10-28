
#!/bin/bash

# Configure Hyperledger Fabric environment
export PATH="${PWD}/../bin:${PATH}"
export FABRIC_CFG_PATH="${PWD}/../config"

# Configuration
ITERATIONS=300

ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

ORG1_CA="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
ORG2_CA="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"
ORG3_CA="${PWD}/organizations/peerOrganizations/org3.example.com/peers/peer0.org3.example.com/tls/ca.crt"

# Peer addresses
PEER1="localhost:7051"
PEER2="localhost:9051"
PEER3="localhost:30001"

# Submit transactions from one organization
submit_transactions() (

    ORG=$1

    # Configure organization identity
    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="Org${ORG}MSP"
    export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org${ORG}.example.com/users/Admin@org${ORG}.example.com/msp"

    case "$ORG" in
        1)
            export CORE_PEER_ADDRESS="$PEER1"
            export CORE_PEER_TLS_ROOTCERT_FILE="$ORG1_CA"
            ;;
        2)
            export CORE_PEER_ADDRESS="$PEER2"
            export CORE_PEER_TLS_ROOTCERT_FILE="$ORG2_CA"
            ;;
        3)
            export CORE_PEER_ADDRESS="$PEER3"
            export CORE_PEER_TLS_ROOTCERT_FILE="$ORG3_CA"
            ;;
        *)
            echo "Invalid organization: $ORG" >&2
            exit 1
            ;;
    esac

    # Distribute transaction IDs across the three organizations
    for ((i=ORG-1; i<ITERATIONS; i+=3)); do

        ASSET_ID="nuevoA${i}"
        OWNER="Rufy${i}"

        echo "Org${ORG}: Creating asset ${ASSET_ID}, owner ${OWNER}"

        peer chaincode invoke \
            -o localhost:7050 \
            --ordererTLSHostnameOverride orderer.example.com \
            --tls \
            --cafile "$ORDERER_CA" \
            -C mychannel \
            -n basic \
            --peerAddresses "$PEER1" \
            --tlsRootCertFiles "$ORG1_CA" \
            --peerAddresses "$PEER2" \
            --tlsRootCertFiles "$ORG2_CA" \
            --peerAddresses "$PEER3" \
            --tlsRootCertFiles "$ORG3_CA" \
            --waitForEvent \
            --waitForEventTimeout 30s \
            -c "{\"function\":\"CreateAsset\",\"Args\":[\"${ASSET_ID}\",\"Rojo\",\"28\",\"${OWNER}\",\"999\"]}"

        if [ $? -ne 0 ]; then
            echo "ERROR: Org${ORG} failed at iteration $i" >&2
            exit 1
        fi

    done

    echo "Org${ORG}: Completed all transactions"

)

echo "Starting concurrent submissions..."

# Run all three organizations concurrently
submit_transactions 1 &
PID1=$!

submit_transactions 2 &
PID2=$!

submit_transactions 3 &
PID3=$!

# Wait for all three processes
wait "$PID1"
STATUS1=$?

wait "$PID2"
STATUS2=$?

wait "$PID3"
STATUS3=$?

echo "---------------------------------"
echo "Org1 exit status: $STATUS1"
echo "Org2 exit status: $STATUS2"
echo "Org3 exit status: $STATUS3"
echo "---------------------------------"

if (( STATUS1 != 0 || STATUS2 != 0 || STATUS3 != 0 )); then
    echo "One or more submission processes failed."
    exit 1
fi

echo "Completed $ITERATIONS chaincode invocations."
