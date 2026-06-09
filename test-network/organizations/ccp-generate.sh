#!/usr/bin/env bash

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function json_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.json
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function json_ccp_peer {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${PEER}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template-peer.json
}

function yaml_ccp_peer {
    local PP=$(one_line_pem $5)
    local CP=$(one_line_pem $6)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${PEER}/$2/" \
        -e "s/\${P0PORT}/$3/" \
        -e "s/\${CAPORT}/$4/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        organizations/ccp-template-peer.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

ORG=1
P0PORT=7051
CAPORT=7054
PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.yaml

#NN: generate connections for peer0 (used by client apps when adding peer listeners).
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer0.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer0.yaml

ORG=2
P0PORT=9051
CAPORT=8054
PEERPEM=organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem
CAPEM=organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem

echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2.yaml

#NN: generate connections for peer0 (used by client apps when adding peer listeners).
echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2-peer0.json
echo "$(yaml_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org2.example.com/connection-org2-peer0.yaml

#NN: generate connections for additional peers.

#NN : org1 peers.

ORG=1
CAPORT=7054

PEERPEM="organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem"
CAPEM="organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem"

for PEER in {1..9}; do

    P0PORT=$((10001 + (PEER - 1) * 10))

    echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json"

    echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml"

done

#NN : org2 peers.

ORG=2
CAPORT=8054

PEERPEM="organizations/peerOrganizations/org2.example.com/tlsca/tlsca.org2.example.com-cert.pem"
CAPEM="organizations/peerOrganizations/org2.example.com/ca/ca.org2.example.com-cert.pem"

for PEER in {1..9}; do

    P0PORT=$((20001 + (PEER - 1) * 10))

    echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org2.example.com/connection-org2-peer${PEER}.json"

    echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org2.example.com/connection-org2-peer${PEER}.yaml"

done

#NN : org3 peers.

ORG=3
CAPORT=3054

PEERPEM="organizations/peerOrganizations/org3.example.com/tlsca/tlsca.org3.example.com-cert.pem"
CAPEM="organizations/peerOrganizations/org3.example.com/ca/ca.org3.example.com-cert.pem"

for PEER in {0..9}; do

    P0PORT=$((30001 + PEER * 10))

    echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org3.example.com/connection-org3-peer${PEER}.json"

    echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" \
        > "organizations/peerOrganizations/org3.example.com/connection-org3-peer${PEER}.yaml"

done


# ORG=1
# PEER=1
# P0PORT=10001
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=2
# P0PORT=10011
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=3
# P0PORT=10021
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=4
# P0PORT=10031
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=5
# P0PORT=10041
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=6
# P0PORT=10051
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=7
# P0PORT=10061
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=8
# P0PORT=10071
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml

# ORG=1
# PEER=9
# P0PORT=10081
# CAPORT=7054
# PEERPEM=organizations/peerOrganizations/org1.example.com/tlsca/tlsca.org1.example.com-cert.pem
# CAPEM=organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem

# echo "$(json_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.json
# echo "$(yaml_ccp_peer $ORG $PEER $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1-peer${PEER}.yaml