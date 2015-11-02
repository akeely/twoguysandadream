package com.twoguysandadream.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.userdetails.AuthenticationUserDetailsService;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.openid.OpenIDAuthenticationToken;
import org.springframework.stereotype.Service;


/**
 * Created by andrewk on 10/18/15.
 */
@Service
public class OpenIdUserDetailsService implements AuthenticationUserDetailsService<OpenIDAuthenticationToken> {

    private static final Logger LOG = LoggerFactory.getLogger(OpenIdUserDetailsService.class);

    @Override public UserDetails loadUserDetails(OpenIDAuthenticationToken token)
        throws UsernameNotFoundException {

        LOG.debug("Loading user [{}] with token [{}]", token.getName(), token);

        return new User(token.getName(), "",
            AuthorityUtils.createAuthorityList("ROLE_USER"));
    }
}
