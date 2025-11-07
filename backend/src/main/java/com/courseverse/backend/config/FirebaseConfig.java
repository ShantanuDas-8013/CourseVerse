package com.courseverse.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;

import javax.annotation.PostConstruct;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @Value("${app.firebase-config-file}")
    private Resource serviceAccountResource;

    @PostConstruct
    public void initialize() {
        try {
            System.out.println("Attempting to load Firebase config from: " + serviceAccountResource.getURL());
            InputStream serviceAccount = serviceAccountResource.getInputStream();

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
                System.out.println("Firebase app initialized successfully.");
            }
        } catch (IOException e) {
            System.err.println("Error initializing Firebase: " + e.getMessage());
            e.printStackTrace();
            // Throw exception to prevent app from starting with broken Firebase
            throw new RuntimeException("Failed to initialize Firebase. Please check firebase config file path.", e);
        }
    }

    // --- ADD THIS NEW METHOD ---
    @Bean
    public Firestore firestore() {
        // This bean provides the Firestore client to other parts of the app
        return FirestoreClient.getFirestore();
    }
}
