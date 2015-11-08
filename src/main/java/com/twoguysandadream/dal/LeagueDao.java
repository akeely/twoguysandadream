package com.twoguysandadream.dal;

import com.twoguysandadream.core.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Created by andrewk on 3/13/15.
 */
@Repository
public class LeagueDao implements LeagueRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Value("${league.findOne}")
    private String findOneQuery;
    @Value("${league.findOneByName}")
    private String findOneByNameQuery;
    @Value("${league.rosterSpots}")
    private String rosterSpotsQuery;
    @Value("${league.findBids}")
    private String findBidsQuery;
    @Value("${league.findRosters}")
    private String findRostersQuery;
    @Value("${league.findTeams}")
    private String findTeamsQuery;

    @Autowired
    public LeagueDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public Optional<League> findOne(long id) {

        Optional<LeagueMetadata> metadata = getMetadata(id);

        return metadata.map(this::getLeagueData);
    }

    @Override public Optional<League> findOneByName(String name) {

        Optional<LeagueMetadata> metadata = getMetadata(name);

        return metadata.map(this::getLeagueData);
    }

    private League getLeagueData(LeagueMetadata metadata) {

        List<Bid> auctionBoard = getAuctionBoard(metadata.getId());
        List<Team> teams = getTeams(metadata.getId());
        return new League(metadata.getId(), metadata.getName(), getRosterSize(metadata),
            metadata.getSalary_cap(), auctionBoard, teams);
    }

    private List<Team> getTeams(long leagueId) {

        Map<String,List<RosteredPlayer>> rosters = getRosters(leagueId);

        return jdbcTemplate.query(findTeamsQuery, Collections.singletonMap("leagueId", leagueId),
            new TeamRowMapper(rosters));
    }

    private Map<String,List<RosteredPlayer>> getRosters(long leagueId) {

        RosteredPlayerCallbackHandler handler = new RosteredPlayerCallbackHandler();
        jdbcTemplate.query(findRostersQuery, Collections.singletonMap("leagueId", leagueId),
            handler);

        return handler.getRosters();
    }

    private List<Bid> getAuctionBoard(long leagueId) {

        return jdbcTemplate.query(findBidsQuery, Collections.singletonMap("leagueId", leagueId),
            new BidRowMapper());
    }

    private int getRosterSize(LeagueMetadata metadata) {

        Sport sport = Sport.valueOf(metadata.getSport().toUpperCase());

        int additionalRosterSpots = jdbcTemplate.queryForObject(rosterSpotsQuery,
            Collections.singletonMap("leagueId", metadata.getId()), Integer.class);

        return sport.getBaseRosterSize() + additionalRosterSpots;
    }

    private Optional<LeagueMetadata> getMetadata(String name) {

        try {
            return Optional.of(jdbcTemplate
                .queryForObject(findOneByNameQuery, Collections.singletonMap("leagueName", name),
                    new BeanPropertyRowMapper<>(LeagueMetadata.class)));
        }
        catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    private Optional<LeagueMetadata> getMetadata(long id) {

        try {
            return Optional.of(jdbcTemplate
                .queryForObject(findOneQuery, Collections.singletonMap("leagueId", id),
                    new BeanPropertyRowMapper<>(LeagueMetadata.class)));
        }
        catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    private String decodeString(String string) {

        try {
            return new String(string.getBytes("ISO-8859-1"), "UTF-8");
        }
        catch (UnsupportedEncodingException e) {

            return string;
        }
    }

    public static class LeagueMetadata {

        private long id;
        private String name;
        private BigDecimal salary_cap;
        private String sport;

        public long getId() {
            return id;
        }

        public void setId(long id) {
            this.id = id;
        }

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

    public class BidRowMapper implements RowMapper<Bid> {

        @Override public Bid mapRow(ResultSet rs, int rowNum) throws SQLException {

            BigDecimal amount = rs.getBigDecimal("price");
            long expirationTime = rs.getLong("time");

            String team = rs.getString("team");

            long id = rs.getLong("playerid");
            String name = decodeString(rs.getString("name"));
            Collection<Position> positions = Collections.singletonList(
                new Position(rs.getString("position")));
            String realTeam = rs.getString("realTeam");
            Player player = new Player(id, name, positions, realTeam);

            return new Bid(team, player, amount, expirationTime);
        }
    }

    public class TeamRowMapper implements RowMapper<Team> {

        private final Map<String,List<RosteredPlayer>> rosters;

        public TeamRowMapper(Map<String, List<RosteredPlayer>> rosters) {
            this.rosters = rosters;
        }

        @Override public Team mapRow(ResultSet rs, int rowNum) throws SQLException {

            long id = rs.getLong("id");
            String name = rs.getString("name");
            Collection<RosteredPlayer> roster = rosters.getOrDefault(name, Collections.emptyList());
            BigDecimal budgetAdjustment = rs.getBigDecimal("money_plusminus");
            int adds = rs.getInt("num_adds");
            return new Team(id,name,roster,budgetAdjustment,adds);
        }
    }

    public class RosteredPlayerCallbackHandler implements RowCallbackHandler {

        private final Map<String,List<RosteredPlayer>> rosters = new HashMap<>();

        @Override public void processRow(ResultSet rs) throws SQLException {

            String team = rs.getString("team");

            long id = rs.getLong("playerid");
            String name = decodeString(rs.getString("name"));
            Collection<Position> positions = Collections.singletonList(
                new Position(rs.getString("position")));
            String realTeam = rs.getString("realTeam");
            Player player = new Player(id, name, positions, realTeam);

            BigDecimal cost = rs.getBigDecimal("price");

            RosteredPlayer rosteredPlayer = new RosteredPlayer(player, cost);
            rosters.putIfAbsent(team, new ArrayList<>());
            rosters.get(team).add(rosteredPlayer);
        }

        public Map<String, List<RosteredPlayer>> getRosters() {
            return rosters;
        }
    }

    private enum Sport {

        BASEBALL(8),
        FOOTBALL(6);

        private final int baseRosterSize;
        private Sport(int baseRosterSize) {
            this.baseRosterSize = baseRosterSize;
        }

        public int getBaseRosterSize() {
            return baseRosterSize;
        }
    }
}
