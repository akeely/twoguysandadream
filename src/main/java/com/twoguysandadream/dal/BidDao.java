package com.twoguysandadream.dal;

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import com.google.common.collect.ImmutableListMultimap;
import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.BidRepository;
import com.twoguysandadream.core.Player;
import com.twoguysandadream.core.Position;

@Repository
public class BidDao implements BidRepository {

    @Value("${bid.findAll}")
    private String findAllQuery;
    @Value("${bid.findAllByLeague}")
    private String findBidsByLeagueQuery;
    @Value("${bid.save}")
    private String saveBidQuery;
    @Value("${bid.create}")
    private String createBidQuery;
    @Value("${bid.remove}")
    private String removeQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public BidDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Map<Long, Collection<Bid>> findAll() {

        BidRowCallbackHandler results = new BidRowCallbackHandler();
        jdbcTemplate.query(findAllQuery, results);

        return results.complete();
    }

    @Override public List<Bid> findAll(long leagueId) {

        return jdbcTemplate.query(findBidsByLeagueQuery, Collections.singletonMap("leagueId", leagueId),
                new BidRowMapper());
    }

    @Override public void save(long leagueId, Bid bid) {

        Map<String, Object> params = getParams(leagueId, bid);

        jdbcTemplate.update(saveBidQuery, params);
    }

    @Override public void create(long leagueId, Bid bid) {

        Map<String, Object> params = getParams(leagueId, bid);

        jdbcTemplate.update(createBidQuery, params);
    }

    @Override
    public void remove(long leagueId, long playerId) {

        Map<String, Long> params = ImmutableMap.<String, Long>builder()
                .put("leagueId", leagueId)
                .put("playerId", playerId)
                .build();

        jdbcTemplate.update(removeQuery, params);
    }

    private Map<String, Object> getParams(long leagueId, Bid bid) {
        return ImmutableMap.<String,Object>builder()
            .put("leagueId", leagueId)
            .put("playerId", bid.getPlayer().getId())
            .put("teamId", bid.getTeamId())
            .put("amount", bid.getAmount())
            .put("expirationTime", bid.getExpirationTime())
            .build();
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
            int rank = rs.getInt("rank");

            Player player = new Player(id, name, positions, realTeam, rank);

            return new Bid(teamId, team, player, amount, expirationTime);
        }
    }

    static class BidRowCallbackHandler implements RowCallbackHandler {

        private final RowMapper<Bid> bidRowMapper;
        private final ImmutableListMultimap.Builder<Long, Bid> bids;

        BidRowCallbackHandler() {
            this.bids = ImmutableListMultimap.builder();
            this.bidRowMapper = new BidRowMapper();
        }

        @Override
        public void processRow(ResultSet rs) throws SQLException {

            Bid bid = bidRowMapper.mapRow(rs, 1);
            long leagueId = rs.getLong("leagueId");

            bids.put(leagueId, bid);
        }

        public Map<Long, Collection<Bid>> complete() {
            return bids.build().asMap();
        }
    }
}
