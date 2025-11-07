package com.courseverse.backend.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class FirebaseJwtFilter extends OncePerRequestFilter {

    // --- INJECT THE UserDetailsService ---
    private final UserDetailsService userDetailsService;

    public FirebaseJwtFilter(UserDetailsService userDetailsService) {
        this.userDetailsService = userDetailsService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String header = request.getHeader("Authorization");

        if (header == null || !header.startsWith("Bearer ")) {
            // If no token is present, continue the filter chain without authenticating
            // Public endpoints will be accessible, secured ones will be blocked by Spring
            // Security
            filterChain.doFilter(request, response);
            return;
        }

        String token = header.substring(7); // Remove "Bearer " prefix

        try {
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(token);
            String uid = decodedToken.getUid();

            // --- THIS IS THE UPDATED PART ---
            // Load user details (including roles) from our database
            UserDetails userDetails = userDetailsService.loadUserByUsername(uid);
            // ---------------------------------

            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    userDetails, // Use the full UserDetails object as the principal
                    null,
                    userDetails.getAuthorities() // Get roles from the UserDetails object
            );

            // Set the authenticated user in Spring Security's context
            SecurityContextHolder.getContext().setAuthentication(authentication);

        } catch (Exception e) {
            // Token is invalid (expired, wrong signature, etc.)
            // Clear the security context
            SecurityContextHolder.clearContext();
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Invalid JWT Token or User Not Found");
            return;
        }

        // Continue the filter chain
        filterChain.doFilter(request, response);
    }
}
