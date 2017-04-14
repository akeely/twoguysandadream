package com.twoguysandadream.dal;

import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.core.RosteredPlayer;
import com.twoguysandadream.core.RosteredPlayerRepository;

@Repository
public class RosteredPlayerDao implements RosteredPlayerRepository {

    @Value("${rosteredPlayer.save}")
    private String saveQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public RosteredPlayerDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }


    @Override
    public void save(long leagueId, long teamId, RosteredPlayer player) {

        jdbcTemplate.update(saveQuery, buildParams(leagueId, teamId, player));
    }

    private SqlParameterSource buildParams(long leagueId, long teamId, RosteredPlayer player) {

        Map<String, Object> params = ImmutableMap.<String, Object>builder()
                .put("leagueId", leagueId)
                .put("teamId", teamId)
                .put("playerId", player.getPlayer().getId())
                .put("price", player.getCost())
                .put("time", String.valueOf(System.currentTimeMillis()))
                .build();

        return new MapSqlParameterSource(params);
    }
}
