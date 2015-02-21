package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
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

    public Collection<TeamStatistics> getTeamStatistics() {

        return teams.stream()
                .map((t) -> new TeamStatistics(t, budget, minimumBid, rosterSize))
                .collect(Collectors.toList());
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
}
