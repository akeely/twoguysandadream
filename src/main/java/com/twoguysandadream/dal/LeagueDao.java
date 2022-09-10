package com.twoguysandadream.dal;

import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.BidRepository;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.LeagueSettings;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamRepository;
import com.twoguysandadream.resources.MissingResourceException;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

@Repository
public class LeagueDao implements LeagueRepository {

    private static final long DAY_IN_MILLIS = TimeUnit.DAYS.toMillis(30L);

    private final NamedParameterJdbcTemplate jdbcTemplate;
    private final BidRepository bidRepository;
    private final TeamRepository teamRepository;

    @Value("${league.findOne}")
    private String findOneQuery;
    @Value("${league.findOneByName}")
    private String findOneByNameQuery;
    @Value("${league.rosterSpots}")
    private String rosterSpotsQuery;
    @Value("${league.updateDraftStatus}")
    private String updateDraftStatusQuery;

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

    @Override
    public Optional<League> findOneByName(String name) {

        Optional<LeagueMetadata> metadata = getMetadata(name);

        return metadata.map(this::getLeagueData);
    }

    @Transactional
    @Override
    public void updateDraftStatus(long id, League.DraftStatus newStatus) throws MissingResourceException {

        League league = findOne(id).orElseThrow(() -> new MissingResourceException("league=" + id));

        Map<String, Object> params = ImmutableMap.<String, Object>builder()
                .put("leagueId", id)
                .put("draftStatus", newStatus.getDescription())
                .build();

        jdbcTemplate.update(updateDraftStatusQuery, params);

        if (league.getDraftStatus().equals(League.DraftStatus.PAUSED) && newStatus.equals(League.DraftStatus.OPEN)) {
            updateAllExpirationTimes(id, league.getSettings().getExpirationTime());
        }

        if (newStatus.equals(League.DraftStatus.PAUSED)) {
            // When pausing the draft, set all expiration times to the future. Unpausing it will reset, but there is
            // a race condition where the bids can be won before the unpause finishes resetting the expiration
            // timestamps.
            updateAllExpirationTimes(id, System.currentTimeMillis() + DAY_IN_MILLIS);
        }
    }

    private void updateAllExpirationTimes(long id, long expirationTime) {
        bidRepository.findAll(id).stream()
                .map(bid -> updateExpirationTime(bid, expirationTime))
                .forEach(bid -> bidRepository.save(id, bid));
    }

    private Bid updateExpirationTime(Bid bid, long expirationTime) {

        return new Bid(bid.getTeamId(), bid.getTeam(), bid.getPlayer(), bid.getAmount(), expirationTime);
    }

    private League getLeagueData(LeagueMetadata metadata) {

        List<Bid> auctionBoard = bidRepository.findAll(metadata.getId());
        List<Team> teams = getTeams(metadata.getId());
        LeagueSettings settings = getSettings(metadata);
        return new League(metadata.getId(), metadata.getName(), settings, auctionBoard, teams, getDraftStatus(metadata),
                getDraftType(metadata));
    }

    private League.DraftStatus getDraftStatus(LeagueMetadata metadata) {

        return League.DraftStatus.fromDescription(metadata.getDraft_status());
    }

    private League.DraftType getDraftType(LeagueMetadata metadata) {
        return League.DraftType.fromDescription(metadata.getDraft_type());
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
        private String draft_status;
        private String draft_type;

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

        public String getDraft_status() {
            return draft_status;
        }

        public void setDraft_status(String draft_status) {
            this.draft_status = draft_status;
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

        public String getDraft_type() {
            return draft_type;
        }

        public void setDraft_type(String draft_type) {
            this.draft_type = draft_type;
        }
    }

    private enum Sport {

        BASEBALL(8),
        FOOTBALL(6);

        private final int baseRosterSize;
        Sport(int baseRosterSize) {
            this.baseRosterSize = baseRosterSize;
        }

        public int getBaseRosterSize() {
            return baseRosterSize;
        }
    }
}
