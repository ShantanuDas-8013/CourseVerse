package com.courseverse.backend.repository;

import com.courseverse.backend.model.User;
import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import org.springframework.stereotype.Repository;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

@Repository
public class UserRepository {

    private final Firestore firestore;
    private static final String COLLECTION_NAME = "users";

    public UserRepository(Firestore firestore) {
        this.firestore = firestore;
    }

    public Optional<User> findById(String uid) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection(COLLECTION_NAME).document(uid);
        ApiFuture<DocumentSnapshot> future = docRef.get();
        DocumentSnapshot document = future.get();

        if (document.exists()) {
            User user = document.toObject(User.class);
            // Manually set the UID from the document ID
            if (user != null) {
                user.setUid(document.getId());
            }
            return Optional.ofNullable(user);
        } else {
            return Optional.empty();
        }
    }

    public void save(User user) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection(COLLECTION_NAME).document(user.getUid());
        ApiFuture<com.google.cloud.firestore.WriteResult> future = docRef.set(user);
        future.get(); // Wait for the write operation to complete
    }

    public List<User> findAll() throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = firestore.collection(COLLECTION_NAME).get();
        QuerySnapshot querySnapshot = future.get();

        List<User> users = new ArrayList<>();
        querySnapshot.getDocuments().forEach(document -> {
            User user = document.toObject(User.class);
            if (user != null) {
                user.setUid(document.getId());
                users.add(user);
            }
        });

        return users;
    }

    public void updateRoles(String uid, List<String> roles) throws ExecutionException, InterruptedException {
        DocumentReference docRef = firestore.collection(COLLECTION_NAME).document(uid);
        ApiFuture<com.google.cloud.firestore.WriteResult> future = docRef.update("roles", roles);
        future.get(); // Wait for the update operation to complete
    }
}
