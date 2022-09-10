package com.twoguysandadream.security;

import static com.twoguysandadream.config.SecurityConfig.ENCODER;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Collection;
import java.util.Optional;

/**
 * Created by andrewk on 11/1/15.
 */
public class AuctionUser extends User {

    private final Long userId;

    public AuctionUser(long userId, String username) {
        super(username, ENCODER.encode("junk"), AuthorityUtils.createAuthorityList("ROLE_USER"));
        this.userId = userId;
    }

    public AuctionUser(String username) {
        super(username, ENCODER.encode("junk"), AuthorityUtils.createAuthorityList("ROLE_USER"));
        this.userId = null;
    }

    public Optional<Long> getId() {
        return Optional.ofNullable(userId);
    }
}
