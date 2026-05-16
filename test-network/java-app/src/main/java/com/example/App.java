package com.example;

import org.hyperledger.fabric.gateway.Identity;
import org.hyperledger.fabric.gateway.Network;
import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.Gateway;
import org.hyperledger.fabric.gateway.Identities;
import org.hyperledger.fabric.sdk.BlockEvent;
import org.hyperledger.fabric.sdk.Enrollment;

import java.nio.file.*;
import java.security.*;
import java.util.HashMap;

/**
 * App to listen to block commit events for peers.
 *
 */
public class App {

    // Map to store gateway instances for different organizations (and soon peers).
    public static HashMap<String, Gateway> gatewayMap = new HashMap<String, Gateway>();

    private static Gateway setupBlockLister(int orgNumber) {

        Gateway gateway = null;

        String basePath = "/home/nono/HLF/fabric-samples/test-network/";

        String mspId = "Org" + orgNumber + "MSP";
        String organizationPathString;
        switch (orgNumber) {
            case 1:
                organizationPathString = "org1";
                break;
            case 2:
                organizationPathString = "org2";
                break;
            default:
                System.out.println("Invalid organization number. Please provide 1 or 2.");
                return null;
        }

        // Set path to the network configuration file,
        // E.g. basePath +
        // "organizations/peerOrganizations/org1.example.com/connection-org1.yaml"
        Path networkConfigPath = Paths.get(
                basePath + "organizations/peerOrganizations/" + organizationPathString + ".example.com/connection-"
                        + organizationPathString + ".yaml");

        // Set paths to the crypto materials (certificate, private key, TLS
        // certificate).
        // E.g. basePath + "organizations/peerOrganizations/org1.example.com"
        Path cryptoPath = Paths
                .get(basePath + "organizations/peerOrganizations/" + organizationPathString + ".example.com");

        // Set paths to the certificate.
        // E.g. basePath +
        // "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/cert.pem"
        Path certPath = cryptoPath.resolve(basePath
                + "organizations/peerOrganizations/" + organizationPathString + ".example.com/users/User1@"
                + organizationPathString + ".example.com/msp/signcerts/cert.pem");

        // Set path to the private key directory (the directory should contain only one
        // file).
        // E.g. basePath +
        // "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore"
        Path keyDir = cryptoPath.resolve(basePath
                + "organizations/peerOrganizations/" + organizationPathString + ".example.com/users/User1@"
                + organizationPathString + ".example.com/msp/keystore");

        // Set path to the TLS certificate.
        // E.g. basePath +
        // "organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem"
        Path tlsCertPath = cryptoPath
                .resolve(basePath + "organizations/peerOrganizations/" + organizationPathString + ".example.com/ca/ca."
                        + organizationPathString + ".example.com-cert.pem");

        // Check if the certificate, key directory, and TLS certificate exist.
        boolean filesPresent = false;
        if (Files.exists(certPath) && Files.exists(keyDir) && Files.exists(tlsCertPath)) {
            System.out.println("\nCertificate, key directory, and TLS certificate found.\n");
            filesPresent = true;
        } else {
            System.out.println("One or more required files/directories are missing:");
            if (!Files.exists(certPath)) {
                System.out.println("Missing certificate: " + certPath);
            }
            if (!Files.exists(keyDir)) {
                System.out.println("Missing key directory: " + keyDir);
            }
            if (!Files.exists(tlsCertPath)) {
                System.out.println("Missing TLS certificate: " + tlsCertPath);
            }
        }
        if (filesPresent) {
            // System.out.println("Certificate path: " + certPath);
            // System.out.println("Key directory path: " + keyDir);
            // System.out.println("TLS certificate path: " + tlsCertPath);
            try {
                Path keyPath = Files.list(keyDir).findFirst().get();
                System.out.println("Key file path: " + keyPath);

                System.out.println("\nReading private key...");
                // Read private key
                Files.list(keyDir).findFirst().ifPresent(keyFilePath -> {
                    System.out.println("Key file path: " + keyFilePath);
                });

                // Get the actual name of the file in the keystore directory (there should be
                // only one file).
                Path keyFilePath = Files.list(keyDir).findFirst().get();

                PrivateKey privateKey = Identities.readPrivateKey(
                        Files.newBufferedReader(keyFilePath));

                System.out.println("\nCreating enrollment...");
                // Create enrollment
                Enrollment enrollment = new Enrollment() {
                    @Override
                    public PrivateKey getKey() {
                        return privateKey;
                    }

                    @Override
                    public String getCert() {
                        try {
                            return Files.readString(certPath);
                        } catch (Exception e) {
                            throw new RuntimeException(e);
                        }
                    }
                };

                System.out.println("\nCreating identity...");
                Identity identity = Identities.newX509Identity(mspId, enrollment);

                Gateway.Builder builder = Gateway.createBuilder()
                        .identity(identity)
                        .networkConfig(networkConfigPath);

                gateway = builder.connect();
                System.out.println("\nSuccessfully connected to the gateway.");

                Network network = gateway.getNetwork("mychannel");

                System.out.println("\nSubscribing to block events...");

                // Create a final variable to hold the organization name for use in the block listener lambda.
                final String listenerOrg = organizationPathString;

                // Block listener.
                network.addBlockListener(blockEvent -> {

                    System.out.println("\n📦 BLOCK COMMITTED");
                    // This is not reliable. The final variable works best.
                    // System.out.println("Peer Id: " +
                    //         blockEvent.getPeer().getName());
                    System.out.println("Block Number: " +
                            blockEvent.getBlockNumber());
                    System.out.println("org: " +
                            listenerOrg);

                    for (BlockEvent.TransactionEvent txEvent : blockEvent.getTransactionEvents()) {

                        System.out.println("TxID: " +
                                txEvent.getTransactionID());

                        System.out.println("Valid: " +
                                txEvent.isValid());
                    }
                });

            } catch (Exception e) {
                System.out.println("NN ===> General error: " + e.getMessage());
                e.printStackTrace();
            }

        }
        return gateway;
    }


    public static void main(String[] args) {

        Gateway gateway = setupBlockLister(1);
        setupBlockLister(2);

        // Get a gateway to submit transactions.

        // Gateway gateway = gatewayMap.get("Org1MSP");
        Network network = gateway.getNetwork("mychannel");
        Contract contract = network.getContract("basic");
        try {

            // Perform a ledger query.

            byte[] queryResult = contract.evaluateTransaction(
                    "ReadAsset",
                    "asset6");

            System.out.println("\nUpdated Asset:");
            String queryResultStr = new String(queryResult);
            System.out.println(queryResultStr);

            byte[] result = contract.submitTransaction(
                    "TransferAsset",
                    "asset6",
                    "Rufino Blanco");

            System.out.println("\nTransaction has been submitted, result: " +
                    new String(result));

            Thread.sleep(600000); // Sleep for a while to allow block event to be processed before the program
                                 // exits.

        } catch (Exception e) {
            System.out.println("NN ===> Error submitting transaction: " + e.getMessage());
            e.printStackTrace();
        }

    }
}