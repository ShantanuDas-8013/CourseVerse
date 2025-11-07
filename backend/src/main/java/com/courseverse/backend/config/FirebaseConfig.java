package com.courseverse.backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.cloud.firestore.Firestore;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    @Value("${app.firebase-config-file:}")
    private String firebaseConfigFile;
    
    @Value("${app.firebase-config-json:}")
    private String firebaseConfigJson;

    @PostConstruct
    public void initialize() {
        try {
            InputStream serviceAccount;
            
            // Try to load from JSON string (environment variable) first
            if (firebaseConfigJson != null && !firebaseConfigJson.trim().isEmpty()) {
                System.out.println("Loading Firebase config from environment variable");
                serviceAccount = new ByteArrayInputStream(firebaseConfigJson.getBytes(StandardCharsets.UTF_8));
            } 
            // Fall back to file path
            else if (firebaseConfigFile != null && !firebaseConfigFile.trim().isEmpty()) {
                System.out.println("Loading Firebase config from file: " + firebaseConfigFile);
                org.springframework.core.io.Resource resource = 
                    new org.springframework.core.io.DefaultResourceLoader().getResource(firebaseConfigFile);
                serviceAccount = resource.getInputStream();
            } 
            else {
                throw new RuntimeException("No Firebase configuration provided. Set either app.firebase-config-json or app.firebase-config-file");
            }

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
            throw new RuntimeException("Failed to initialize Firebase. Please check firebase config.", e);
        }
    }

    // --- ADD THIS NEW METHOD ---
    @Bean
    public Firestore firestore() {
        // This bean provides the Firestore client to other parts of the app
        return FirestoreClient.getFirestore();
    }
}
