package com.courseverse.backend.config;

import com.courseverse.backend.security.FirebaseJwtFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;
import org.springframework.beans.factory.annotation.Value;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity // --- ADD THIS ANNOTATION ---
public class WebSecurityConfig {

    private final FirebaseJwtFilter firebaseJwtFilter;
    
    @Value("${CORS_ALLOWED_ORIGINS:}")
    private String corsAllowedOrigins;

    public WebSecurityConfig(FirebaseJwtFilter firebaseJwtFilter) {
        this.firebaseJwtFilter = firebaseJwtFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // Enable CORS with custom configuration
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // Disable CSRF (Cross-Site Request Forgery) - common for stateless APIs
                .csrf(csrf -> csrf.disable())

                // We are using token-based auth, so sessions are stateless
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

        .authorizeHttpRequests(authz -> authz
                        // --- UPDATED RULES ---
                        .requestMatchers("/api/v1/courses/health").permitAll() // Old health check
            .requestMatchers(org.springframework.http.HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/v1/courses").permitAll() // Browse
                                                                                                                 // courses
                        .requestMatchers(org.springframework.http.HttpMethod.GET, "/api/v1/courses/**").permitAll() // Get
                                                                                                                    // single
                                                                                                                    // course
                        // ---------------------

                        // All other requests must be authenticated
                        .anyRequest().authenticated())

                // Add our custom Firebase filter *before* the standard Spring authentication
                // filter
                .addFilterBefore(firebaseJwtFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        // If specific origins are provided via environment variable, use them. Otherwise allow all origins (dev).
        if (corsAllowedOrigins != null && !corsAllowedOrigins.isBlank()) {
            List<String> origins = Arrays.stream(corsAllowedOrigins.split(","))
                    .map(String::trim)
                    .toList();
            configuration.setAllowedOrigins(origins);
        } else {
            configuration.setAllowedOriginPatterns(List.of("*"));
        }
        configuration.setAllowedMethods(Arrays.asList("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }
}
