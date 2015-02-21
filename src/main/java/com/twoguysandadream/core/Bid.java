package com.twoguysandadream.core;

import java.math.BigDecimal;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Bid {

    private final BigDecimal amount;
    private final long expirationTime;
    private final Player player;
    private final Team team;

    public Bid(Team team, Player player, BigDecimal amount, long expirationTime) {

        this.amount = amount;
        this.expirationTime = expirationTime;
        this.player = player;
        this.team = team;
    }
}
