package com.twoguysandadream.core;

import java.math.BigDecimal;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class RosteredPlayer {

    private final Player player;
    private final BigDecimal cost;
    private final String time;
    private final String rfaOverride;

    public RosteredPlayer(Player player, BigDecimal cost, String time, String rfaOverride) {
        this.player = player;
        this.cost = cost;
        this.time = time;
        this.rfaOverride = rfaOverride;
    }

    public Player getPlayer() {
        return player;
    }

    public BigDecimal getCost() {
        return cost;
    }

    public String getTime() {
        return time;
    }

    public String getRfaOverride() {
        return rfaOverride;
    }
}
