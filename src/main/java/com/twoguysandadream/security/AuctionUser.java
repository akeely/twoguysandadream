package com.twoguysandadream.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.userdetails.User;

import java.util.Collection;

/**
 * Created by andrewk on 11/1/15.
 */
public class AuctionUser extends User {

    private final long userId;

    public AuctionUser(long userId, String username) {

        super(username, "", AuthorityUtils.createAuthorityList("ROLE_USER"));
        this.userId = userId;
    }

    public long getId() {
        return userId;
    }
}
