package com.twoguysandadream.dal;

import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Repository;

import java.util.Collections;
import java.util.Map;

/**
 * Created by andrewk on 11/1/15.
 */
@Repository
public class AuctionUserDao implements AuctionUserRepository {

    @Value("${user.findOne}")
    private String findOneQuery;
    @Value("${user.create}")
    private String createQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public AuctionUserDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public AuctionUser findOrCreate(String openIdToken) {

        SqlParameterSource params = buildParams(openIdToken);

        try {
            long id = jdbcTemplate.queryForObject(findOneQuery, params, Long.class);
            return new AuctionUser(id, openIdToken);
        }
        catch (EmptyResultDataAccessException e) {
            return create(openIdToken, params);
        }
    }

    private AuctionUser create(String openIdToken, SqlParameterSource params) {

        GeneratedKeyHolder keyHolder = new GeneratedKeyHolder();
        jdbcTemplate.update(createQuery, params, keyHolder);
        long id = keyHolder.getKey().longValue();

        return new AuctionUser(id, openIdToken);
    }

    private SqlParameterSource buildParams(String openIdToken) {

        return new MapSqlParameterSource("openIdToken", openIdToken);
    }
}
