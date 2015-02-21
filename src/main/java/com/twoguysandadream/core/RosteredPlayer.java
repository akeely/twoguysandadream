package com.twoguysandadream.core;

import java.math.BigDecimal;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class RosteredPlayer {

    private final Player player;
    private final BigDecimal cost;

    public RosteredPlayer(Player player, BigDecimal cost) {
        this.player = player;
        this.cost = cost;
    }

    public Player getPlayer() {
        return player;
    }

    public BigDecimal getCost() {
        return cost;
    }
}
