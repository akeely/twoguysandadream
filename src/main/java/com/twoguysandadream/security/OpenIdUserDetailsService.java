package com.twoguysandadream.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.AuthorityUtils;
import org.springframework.security.core.userdetails.AuthenticationUserDetailsService;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.openid.OpenIDAuthenticationToken;
import org.springframework.stereotype.Service;

@Service
public class OpenIdUserDetailsService implements AuthenticationUserDetailsService<OpenIDAuthenticationToken> {

    private static final Logger LOG = LoggerFactory.getLogger(OpenIdUserDetailsService.class);

    private final AuctionUserRepository userRepository;

    @Autowired
    public OpenIdUserDetailsService(AuctionUserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override public AuctionUser loadUserDetails(OpenIDAuthenticationToken token)
        throws UsernameNotFoundException {

        LOG.debug("Loading user [{}] with token [{}]", token.getName(), token);

        return userRepository.findOne(token.getName())
            .orElse(new AuctionUser(token.getName()));
    }
}
