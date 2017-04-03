package com.twoguysandadream.core;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class League {

    private final long id;
    private final String name;
    private final LeagueSettings settings;

    private final List<Bid> auctionBoard;
    private final List<Team> teams;
    private final boolean isPaused;

    public League(long id, String name, LeagueSettings settings, List<Bid> auctionBoard, List<Team> teams,
        boolean isPaused) {

        this.id = id;
        this.name = name;
        this.settings = settings;
        this.auctionBoard = auctionBoard;
        this.teams = teams;
        this.isPaused = isPaused;
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
        return isPaused;
    }

    private TeamStatistics toStatistics(Team team) {
        return new TeamStatistics(team, settings);
    }
}
