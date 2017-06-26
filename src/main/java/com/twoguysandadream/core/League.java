package com.twoguysandadream.core;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableList;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class League {

    private static final Logger LOG = LoggerFactory.getLogger(League.class);

    private final long id;
    private final String name;
    private final LeagueSettings settings;

    private final List<Bid> auctionBoard;
    private final List<Team> teams;
    private final DraftStatus draftStatus;

    public League(long id, String name, LeagueSettings settings, List<Bid> auctionBoard, List<Team> teams,
        DraftStatus draftStatus) {

        this.id = id;
        this.name = name;
        this.settings = settings;
        this.auctionBoard = auctionBoard;
        this.teams = teams;
        this.draftStatus = draftStatus;
    }

    public Map<Long,TeamStatistics> getTeamStatistics() {

        return teams.stream()
            .collect(Collectors.toMap(Team::getId, this::toStatistics));
    }

    public List<Team> getTeams() {

        return teams;
    }

    public List<Bid> getAuctionBoard() {

        return auctionBoard;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public LeagueSettings getSettings() {
        return settings;
    }

    public boolean isPaused() {
        return draftStatus.equals(DraftStatus.PAUSED);
    }

    public String getDraftStatusDescription() {
        return draftStatus.getDescription();
    }

    public DraftStatus getDraftStatus() {
        return draftStatus;
    }

    private TeamStatistics toStatistics(Team team) {
        return new TeamStatistics(team, settings);
    }

    public enum DraftStatus {

        READY("ready"),
        RFA("rfa"),
        OPEN("open"),
        PAUSED("paused"),
        CLOSED("closed");

        private final String description;

        DraftStatus(String description) {
            this.description = description;
        }

        public String getDescription() {
            return description;
        }

        public static DraftStatus fromDescription(String description) {

            return ImmutableList.copyOf(DraftStatus.values()).stream()
                    .filter(s -> s.description.equalsIgnoreCase(description))
                    .findAny()
                    .orElseGet(() -> {
                        LOG.warn("Unknown draft status description: {}.", description);
                        return OPEN;
                    });
        }
    }
}
