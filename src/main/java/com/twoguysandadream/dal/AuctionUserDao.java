package com.twoguysandadream.dal;

import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.*;

/**
 * Created by andrewk on 11/1/15.
 */
@Repository
public class AuctionUserDao implements AuctionUserRepository {

    private static final Logger LOG = LoggerFactory.getLogger(AuctionUserDao.class);

    @Value("${user.create}")
    private String createQuery;
    @Value("${user.findTeam}")
    private String findTeamQuery;
    @Value("${user.findOwner}")
    private String findOwnerQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public AuctionUserDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public AuctionUser findOrCreate(Object principal) {

        if (principal instanceof AuctionUser) {
            return (AuctionUser) principal;
        }
        if (principal instanceof OAuth2User) {
            String email = ((OAuth2User) principal).getAttribute("email");
            return findByEmail(email).orElseGet(() -> create(email));
        }
        if (principal instanceof String) {
            String email = (String) principal;
            return findByEmail(email).orElseGet(() -> create(email));
        }

        throw new IllegalArgumentException("Unknown principal class: " + principal.getClass().getCanonicalName());
    }


    @Override
    public Optional<AuctionUser> findByEmail(String email) {

        String query = "SELECT id FROM passwd WHERE email=:email";

        SqlParameterSource params = new MapSqlParameterSource("email", email);

        try {
            long id = jdbcTemplate.queryForObject(query, params, Long.class);
            return Optional.of(new AuctionUser(id, email));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override
    public OptionalLong findTeamId(long userId, long leagueId) {

        Map<String, Object> params = new HashMap<>(2);
        params.put("userId", userId);
        params.put("leagueId", leagueId);

        try {
            long id = jdbcTemplate.queryForObject(findTeamQuery, params, Long.class);
            return OptionalLong.of(id);
        } catch (EmptyResultDataAccessException e) {
            return OptionalLong.empty();
        }
    }

    @Override
    public Optional<String> findOwner(long userId) {
        try {
            String name = jdbcTemplate.queryForObject(findOwnerQuery, Collections.singletonMap("userId", userId),
                    String.class);
            return Optional.of(name);
        }
        catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    private AuctionUser create(String email) {

        SqlParameterSource params = buildParams(email);

        LOG.info("Found new user with email {}. Creating...", email);

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(createQuery, params, keyHolder);
        long id = keyHolder.getKey().longValue();

        return new AuctionUser(id, email);
    }

    private SqlParameterSource buildParams(String email) {

        return new MapSqlParameterSource("email", email);
    }
}
