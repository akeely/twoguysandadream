package com.twoguysandadream.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
public class DbUserDetailsService implements UserDetailsService {

    private static final Logger LOG = LoggerFactory.getLogger(DbUserDetailsService.class);

    private final AuctionUserRepository userRepository;

    @Autowired
    public DbUserDetailsService(AuctionUserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public AuctionUser loadUserByUsername(String s) throws UsernameNotFoundException {
        LOG.info("Finding user {}", s);
        AuctionUser user = userRepository.findByEmail(s).orElseThrow(() -> new UsernameNotFoundException(s));
        LOG.info("Found user {}", user.getUsername());
        return user;
    }
}
