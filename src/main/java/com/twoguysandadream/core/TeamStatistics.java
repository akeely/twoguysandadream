package com.twoguysandadream.core;

import java.math.BigDecimal;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class TeamStatistics {

    private final BigDecimal availableBudget;
    private final BigDecimal maxBid;
    private final int openRosterSpots;
    private final int adds;

    public TeamStatistics(BigDecimal availableBudget, BigDecimal maxBid, int openRosterSpots,
            int adds) {

        this.availableBudget = availableBudget;
        this.maxBid = maxBid;
        this.openRosterSpots = openRosterSpots;
        this.adds = adds;
    }

    public TeamStatistics(Team team, LeagueSettings settings) {

        this.adds = team.getAdds();
        this.openRosterSpots = settings.getRosterSize() - team.getRoster().size();
        this.availableBudget = settings.getBudget()
            .add(team.getBudgetAdjustment())
            .subtract(team.getRoster().stream()
                .map(RosteredPlayer::getCost)
                .reduce((x,y) -> x.add(y))
                .orElse(BigDecimal.ZERO));
        if (openRosterSpots == 0) {
            this.maxBid = BigDecimal.ZERO;
        } else {
            this.maxBid = availableBudget
                    .subtract(settings.getMinimumBid().multiply(new BigDecimal(openRosterSpots - 1)));
        }
    }

    public BigDecimal getAvailableBudget() {
        return availableBudget;
    }

    public BigDecimal getMaxBid() {
        return maxBid;
    }

    public int getOpenRosterSpots() {
        return openRosterSpots;
    }

    public int getAdds() {
        return adds;
    }
}
