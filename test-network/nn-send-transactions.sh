
#!/bin/bash

# Configure Hyperledger Fabric environment
export PATH="${PWD}/../bin:${PATH}"
export FABRIC_CFG_PATH="${PWD}/../config"

# Configure peer as Org1
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="Org1MSP"
export CORE_PEER_TLS_ROOTCERT_FILE="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${PWD}/organizations/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp"
export CORE_PEER_ADDRESS="localhost:7051"

# Configuration
ITERATIONS=100

ORDERER_CA="${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem"

ORG1_CA="${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt"

ORG2_CA="${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt"

# Invoke chaincode repeatedly
for ((i=0; i<ITERATIONS; i++)); do

    # Cycle through asset1 to asset6
    ASSET_ID="nuevoDos${i}"

    # Generate new owner
    OWNER="Rufy${i}"

    echo "Iteration $i: Creating new asset $ASSET_ID with owner $OWNER"

    peer chaincode invoke \
        -o localhost:7050 \
        --ordererTLSHostnameOverride orderer.example.com \
        --tls \
        --cafile "$ORDERER_CA" \
        -C mychannel \
        -n basic \
        --peerAddresses localhost:7051 \
        --tlsRootCertFiles "$ORG1_CA" \
        --peerAddresses localhost:9051 \
        --tlsRootCertFiles "$ORG2_CA" \
        --waitForEvent \
        --waitForEventTimeout 30s \
        -c "{\"function\":\"CreateAsset\",\"Args\":[\"${ASSET_ID}\",\"Rojo\",\"28\",\"${OWNER}\",\"999\"]}"

    if [ $? -ne 0 ]; then
        echo "ERROR: Invocation failed at iteration $i"
        exit 1
    fi

done

echo "Completed $ITERATIONS chaincode invocations."
