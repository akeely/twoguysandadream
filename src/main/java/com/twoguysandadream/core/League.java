package com.twoguysandadream.core;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.collect.ImmutableList;

public class League {

    private static final Logger LOG = LoggerFactory.getLogger(League.class);

    private final long id;
    private final String name;
    private final LeagueSettings settings;

    private final List<Bid> auctionBoard;
    private final List<Team> teams;
    private final DraftStatus draftStatus;
    private final DraftType draftType;

    public League(long id, String name, LeagueSettings settings, List<Bid> auctionBoard, List<Team> teams,
        DraftStatus draftStatus, DraftType draftType) {

        this.id = id;
        this.name = name;
        this.settings = settings;
        this.auctionBoard = auctionBoard;
        this.teams = teams;
        this.draftStatus = draftStatus;
        this.draftType = draftType;
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

    public DraftType getDraftType() {
        return draftType;
    }

    public String getDraftTypeDescription() {
        return draftType.getDescription();
    }

    private TeamStatistics toStatistics(Team team) {
        return new TeamStatistics(team, settings);
    }

    public enum DraftType {

        AUCTION("auction"),
        RFA("rfa");

        private final String description;

        DraftType(String description) {
            this.description = description;
        }

        public String getDescription() {
            return description;
        }

        public static DraftType fromDescription(String description) {

            return ImmutableList.copyOf(DraftType.values()).stream()
                    .filter(t -> t.description.equalsIgnoreCase(description))
                    .findAny()
                    .orElseGet(() -> {
                        LOG.warn("Unknown draft type description: {}.", description);
                        return AUCTION;
                    });
        }
    }

    public enum DraftStatus {

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
