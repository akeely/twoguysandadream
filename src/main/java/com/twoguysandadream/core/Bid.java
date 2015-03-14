package com.twoguysandadream.core;

import java.math.BigDecimal;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Bid {

    private final BigDecimal amount;
    private final long expirationTime;
    private final Player player;
    private final String team;

    public Bid(String team, Player player, BigDecimal amount, long expirationTime) {

        this.amount = amount;
        this.expirationTime = expirationTime;
        this.player = player;
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

    public String getTeam() {
        return team;
    }
}
