package com.twoguysandadream.dal;

import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.BidRepository;
import com.twoguysandadream.core.Player;
import com.twoguysandadream.core.Position;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.BeanPropertySqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@Repository
public class BidDao implements BidRepository {

    @Value("${bid.findAll}")
    private String findBidsQuery;
    @Value("${bid.save}")
    private String saveBidQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public BidDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override public List<Bid> findAll(long leagueId) {

        return jdbcTemplate.query(findBidsQuery, Collections.singletonMap("leagueId", leagueId), new BidRowMapper());
    }

    @Override public void save(long leagueId, Bid bid) {

        Map<String, Object> params = ImmutableMap.<String,Object>builder()
            .put("leagueId", leagueId)
            .put("playerId", bid.getPlayer().getId())
            .put("teamId", bid.getTeamId())
            .put("amount", bid.getAmount())
            .put("expirationTime", bid.getExpirationTime())
            .build();

        jdbcTemplate.update(saveBidQuery, params);
    }

    private static String decodeString(String string) {

        try {
            return new String(string.getBytes("ISO-8859-1"), "UTF-8");
        }
        catch (UnsupportedEncodingException e) {

            return string;
        }
    }

    static class BidRowMapper implements RowMapper<Bid> {

        @Override public Bid mapRow(ResultSet rs, int rowNum) throws SQLException {

            BigDecimal amount = rs.getBigDecimal("price");
            long expirationTime = rs.getLong("time");

            long teamId = rs.getLong("teamId");
            String team = rs.getString("team");

            long id = rs.getLong("playerid");
            String name = decodeString(rs.getString("name"));
            Collection<Position> positions = Collections.singletonList(
                new Position(rs.getString("position")));
            String realTeam = rs.getString("realTeam");
            Player player = new Player(id, name, positions, realTeam);

            return new Bid(teamId, team, player, amount, expirationTime);
        }
    }
}
