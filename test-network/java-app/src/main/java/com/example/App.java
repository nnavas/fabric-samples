package com.example;

import org.hyperledger.fabric.gateway.Identity;
import org.hyperledger.fabric.gateway.X509Identity;
import org.hyperledger.fabric.gateway.Identities;

import org.hyperledger.fabric.sdk.Enrollment;

import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;

import java.io.IOException;
import java.nio.file.*;
import java.security.*;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.concurrent.TimeUnit;

/**
 * Hello world!
 *
 */
public class App {
    public static void main(String[] args) {

        String basePath = "/home/nono/HLF/fabric-samples/test-network/";
        Path cryptoPath = Paths.get(basePath + "organizations/peerOrganizations/org1.example.com");
        Path certPath = cryptoPath.resolve(basePath
                + "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/signcerts/cert.pem");
        Path keyDir = cryptoPath.resolve(basePath
                + "organizations/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore");
        Path tlsCertPath = cryptoPath
                .resolve(basePath + "organizations/peerOrganizations/org1.example.com/ca/ca.org1.example.com-cert.pem");

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
            System.out.println("Certificate path: " + certPath);
            System.out.println("Key directory path: " + keyDir);
            System.out.println("TLS certificate path: " + tlsCertPath);
            try {
                Path keyPath = Files.list(keyDir).findFirst().get();
                System.out.println("Key file path: " + keyPath);

                // Load identity.
                // Identity identity = new X509Identity("Org1MSP",
                // Identities.readX509Certificate(Files.newBufferedReader(certPath)));

                // Identity identity = Identities.newX509Identity(
                // "Org1MSP",
                // Identities.readX509Certificate(Files.newBufferedReader(certPath))
                // );

                System.out.println("\nReading certificate...");
                // Read cert
                X509Certificate certificate = Identities.readX509Certificate(
                        Files.newBufferedReader(certPath));

                System.out.println("\nReading private key...");
                // Read private key
                Files.list(keyDir).findFirst().ifPresent(keyFilePath -> {
                    System.out.println("Key file path: " + keyFilePath);
                });

                // Get the actual name of the file in the keystore directory (there should be only one file).
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
                Identity identity = Identities.newX509Identity("Org1MSP", enrollment);

            } catch (IOException e) {
                e.printStackTrace();
            } catch (CertificateException e) {
                e.printStackTrace();
            } catch (InvalidKeyException e) {
                e.printStackTrace();
            }

        }
    }
}