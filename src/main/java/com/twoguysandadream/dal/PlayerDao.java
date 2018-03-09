package com.twoguysandadream.dal;

import java.io.UnsupportedEncodingException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

import com.twoguysandadream.core.Player;
import com.twoguysandadream.core.PlayerRepository;
import com.twoguysandadream.core.Position;

@Repository
public class PlayerDao implements PlayerRepository {

    @Value("${player.findOne}")
    private String findOneQuery;
    @Value("${player.findAllAvailable}")
    private String findAllAvailableQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public PlayerDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<Player> findOne(long playerId) {

        SqlParameterSource params = new MapSqlParameterSource("playerId", playerId);
        try {
            Player player = jdbcTemplate.queryForObject(findOneQuery, params, new PlayerRowMapper());
            return Optional.of(player);
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override
    public List<Player> findAllAvailable(long leagueId) {

        return jdbcTemplate.query(findAllAvailableQuery, new MapSqlParameterSource("leagueId", leagueId),
            new PlayerRowMapper());
    }

    private static String decodeString(String string) {

        try {
            return new String(string.getBytes("ISO-8859-1"), "UTF-8");
        }
        catch (UnsupportedEncodingException e) {

            return string;
        }
    }

    static class PlayerRowMapper implements RowMapper<Player> {

        @Override public Player mapRow(ResultSet rs, int rowNum) throws SQLException {

            long id = rs.getLong("playerid");
            String name = decodeString(rs.getString("name"));
            Collection<Position> positions = Collections.singletonList(
                new Position(rs.getString("position")));
            String realTeam = rs.getString("team");
            int rank = rs.getInt("rank");
            return new Player(id, name, positions, realTeam, rank);
        }
    }
}
