package com.twoguysandadream.dal;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.rowset.SqlRowSet;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.Map;
import java.util.Optional;

/**
 * Created by andrewk on 3/13/15.
 */
@Repository
public class LeagueDao implements LeagueRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Value("${league.findOne}")
    private String findOneQuery;

    public void setFindOneQuery(String findOneQuery) {
        this.findOneQuery = findOneQuery;
    }

    @Autowired
    public LeagueDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override public Optional<League> findOneByName(String name) {
        LeagueMetadata result;
        try {
             result = jdbcTemplate
                .queryForObject(findOneQuery, Collections.singletonMap("leagueName", name),
                    new BeanPropertyRowMapper<LeagueMetadata>(LeagueMetadata.class));
        }
        catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }


        League league = new League(-1L, result.getName(), 8,
            result.getSalary_cap(), Collections.emptyList(), Collections.emptyList());

        return Optional.of(league);
    }

    public static class LeagueMetadata {

        private String name;
        private BigDecimal salary_cap;
        private String sport;

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public BigDecimal getSalary_cap() {
            return salary_cap;
        }

        public void setSalary_cap(BigDecimal salary_cap) {
            this.salary_cap = salary_cap;
        }

        public String getSport() {
            return sport;
        }

        public void setSport(String sport) {
            this.sport = sport;
        }
    }
}