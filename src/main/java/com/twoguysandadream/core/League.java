package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class League {

    private final long id;
    private final String name;
    private final int rosterSize;
    private final BigDecimal budget;
    private final BigDecimal minimumBid = new BigDecimal(BigInteger.valueOf(5), 1);
    private final List<Bid> auctionBoard;
    private final List<Team> teams;

    public League(long id, String name, int rosterSize, BigDecimal budget, List<Bid> auctionBoard,
            List<Team> teams) {

        this.id = id;
        this.name = name;
        this.rosterSize = rosterSize;
        this.budget = budget;
        this.auctionBoard = auctionBoard;
        this.teams = teams;
    }

    public Map<Team,TeamStatistics> getTeamStatistics() {

        return teams.stream()
                .map((t) -> {
                    TeamStatistics stats = new TeamStatistics (t, budget, minimumBid, rosterSize);
                    return toMapEntry(t, stats);
                })
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    public Map<Team, Collection<RosteredPlayer>> getRosters() {

        return teams.stream()
                .collect(Collectors.toMap(
                    Function.identity(),
                    Team::getRoster,
                    (s, a) -> s)
                );
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

    private <K,V> Map.Entry<K,V> toMapEntry(K key, V value) {

        return new AbstractMap.SimpleEntry<K,V>(key, value);
    }
}
