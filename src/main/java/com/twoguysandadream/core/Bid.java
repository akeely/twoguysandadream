package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.util.concurrent.TimeUnit;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Bid {

    private final BigDecimal amount;
    private final long expirationTime;
    private final Player player;
    private final Long teamId;
    private final String team;

    public Bid(Long teamId, String team, Player player, BigDecimal amount, long expirationTime) {

        this.amount = amount;
        this.expirationTime = expirationTime;
        this.player = player;
        this.teamId = teamId;
        this.team = team;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public long getExpirationTime() {
        return expirationTime;
    }

    public Player getPlayer() {
        return player;
    }

    public Long getTeamId() {
        return teamId;
    }

    public String getTeam() {
        return team;
    }

    public long getSecondsRemaining() {

        long millisRemaining = expirationTime - System.currentTimeMillis();
        return TimeUnit.MILLISECONDS.toSeconds(millisRemaining);
    }
}
