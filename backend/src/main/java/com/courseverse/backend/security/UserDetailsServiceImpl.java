package com.courseverse.backend.security;

import com.courseverse.backend.model.User;
import com.courseverse.backend.repository.UserRepository;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    public UserDetailsServiceImpl(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    /**
     * Loads user details by UID. If the user does not exist in Firestore,
     * it provisions a new student user automatically.
     */
    @Override
    public UserDetails loadUserByUsername(String uid) throws UsernameNotFoundException {
        try {
            // 1. Try to find the user in our Firestore 'users' collection
            Optional<User> userOptional = userRepository.findById(uid);

            User user;
            if (userOptional.isPresent()) {
                // 2. User exists, use them
                user = userOptional.get();
            } else {
                // 3. User NOT found. This is a NEW USER. Provision them.
                System.out.println("User not found in Firestore, provisioning new user with UID: " + uid);
                user = createNewStudentUser(uid);
            }

            // 4. Convert our List<String> roles to Spring's List<GrantedAuthority>
            List<GrantedAuthority> authorities = user.getRoles().stream()
                    .map(SimpleGrantedAuthority::new)
                    .collect(Collectors.toList());

            // 5. Return Spring Security's User object
            return new org.springframework.security.core.userdetails.User(
                    user.getUid(),
                    "", // We don't use passwords, so it can be empty
                    authorities);

        } catch (Exception e) {
            throw new UsernameNotFoundException("Error fetching or creating user: " + e.getMessage());
        }
    }

    /**
     * Helper method to create a new User document in Firestore.
     */
    private User createNewStudentUser(String uid) {
        try {
            // 1. Fetch the user's data from Firebase Auth
            UserRecord userRecord = FirebaseAuth.getInstance().getUser(uid);

            // 2. Create our new User model
            User newUser = new User();
            newUser.setUid(uid);
            newUser.setEmail(userRecord.getEmail());
            newUser.setDisplayName(userRecord.getDisplayName());

            // 3. Assign the default role
            newUser.setRoles(List.of(SecurityRoles.ROLE_STUDENT.name()));

            // 4. Save the new user to our Firestore 'users' collection
            // We're saving this *synchronously* by calling .get()
            userRepository.save(newUser);

            System.out.println("Successfully created new user: " + userRecord.getEmail());
            return newUser;

        } catch (Exception e) {
            // This is a critical failure (e.g., Firebase Auth is down)
            throw new RuntimeException("Could not provision new user: " + e.getMessage());
        }
    }
}
