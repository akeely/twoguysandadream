package com.twoguysandadream.dal;

import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalLong;

/**
 * Created by andrewk on 11/1/15.
 */
@Repository
public class AuctionUserDao implements AuctionUserRepository {

    private static final Logger LOG = LoggerFactory.getLogger(AuctionUserDao.class);

    @Value("${user.findOne}")
    private String findOneQuery;
    @Value("${user.create}")
    private String createQuery;
    @Value("${user.findTeam}")
    private String findTeamQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public AuctionUserDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public AuctionUser findOrCreate(String openIdToken) {

        return findOneInternal(openIdToken).orElseGet(() -> create(openIdToken));
    }

    @Override
    public Optional<AuctionUser> findOne(String openIdToken) {
        return findOneInternal(openIdToken);
    }

    @Override
    public OptionalLong findTeamId(AuctionUser user, long leagueId) {

        Map<String, Object> params = new HashMap<>(2);
        params.put("userId", user.getId());
        params.put("leagueId", leagueId);

        try {
            long id = jdbcTemplate.queryForObject(findTeamQuery, params, Long.class);
            return OptionalLong.of(id);
        } catch (EmptyResultDataAccessException e) {
            return OptionalLong.empty();
        }
    }

    private Optional<AuctionUser> findOneInternal(String openIdToken) {

        SqlParameterSource params = buildParams(openIdToken);

        try {
            long id = jdbcTemplate.queryForObject(findOneQuery, params, Long.class);
            return Optional.of(new AuctionUser(id, openIdToken));
        }
        catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    private AuctionUser create(String openIdToken) {

        SqlParameterSource params = buildParams(openIdToken);

        LOG.info("Found new user with openIdToken {}. Creating...", openIdToken);

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(createQuery, params, keyHolder);
        long id = keyHolder.getKey().longValue();

        return new AuctionUser(id, openIdToken);
    }

    private SqlParameterSource buildParams(String openIdToken) {

        return new MapSqlParameterSource("openIdToken", openIdToken);
    }
}
