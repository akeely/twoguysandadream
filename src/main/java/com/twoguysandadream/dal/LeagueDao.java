package com.twoguysandadream.dal;

import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.BidRepository;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.LeagueSettings;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Repository
public class LeagueDao implements LeagueRepository {

    private final NamedParameterJdbcTemplate jdbcTemplate;
    private final BidRepository bidRepository;
    private final TeamRepository teamRepository;

    @Value("${league.findOne}")
    private String findOneQuery;
    @Value("${league.findOneByName}")
    private String findOneByNameQuery;
    @Value("${league.rosterSpots}")
    private String rosterSpotsQuery;

    @Autowired
    public LeagueDao(NamedParameterJdbcTemplate jdbcTemplate, BidRepository bidRepository,
        TeamRepository teamRepository) {
        this.jdbcTemplate = jdbcTemplate;
        this.bidRepository = bidRepository;
        this.teamRepository = teamRepository;
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

        List<Bid> auctionBoard = bidRepository.findAll(metadata.getId());
        List<Team> teams = getTeams(metadata.getId());
        LeagueSettings settings = getSettings(metadata);
        return new League(metadata.getId(), metadata.getName(), settings, auctionBoard, teams);
    }

    private LeagueSettings getSettings(LeagueMetadata metadata) {
        int rosterSize = getRosterSize(metadata);
        return new LeagueSettings(rosterSize, metadata.getSalary_cap(), metadata.getAuction_length(),
            metadata.getBid_time_ext(), metadata.getBid_time_ext());
    }

    private List<Team> getTeams(long leagueId) {

        return teamRepository.findAll(leagueId);
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

    public static class LeagueMetadata {

        private long id;
        private String name;
        private BigDecimal salary_cap;
        private String sport;
        private long auction_length, bid_time_ext, bid_time_buff;

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

        public long getAuction_length() {
            return auction_length;
        }

        public void setAuction_length(long auction_length) {
            this.auction_length = auction_length;
        }

        public long getBid_time_ext() {
            return bid_time_ext;
        }

        public void setBid_time_ext(long bid_time_ext) {
            this.bid_time_ext = bid_time_ext;
        }

        public long getBid_time_buff() {
            return bid_time_buff;
        }

        public void setBid_time_buff(long bid_time_buff) {
            this.bid_time_buff = bid_time_buff;
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
