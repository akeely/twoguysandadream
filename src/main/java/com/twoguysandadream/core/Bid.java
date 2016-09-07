package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.util.Optional;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Bid {

    private final BigDecimal amount;
    private final long expirationTime;
    private final Player player;
    private final String team;
    private final String rfaOverride;
    private final String previousTeam;
    private final long currentTime;

    public Bid(String team, Player player, BigDecimal amount, long expirationTime, String rfaOverride,
        String previousTeam, long currentTime) {

        this.amount = amount;
        this.expirationTime = expirationTime;
        this.player = player;
        this.team = team;
        this.rfaOverride = rfaOverride;
        this.previousTeam = previousTeam;
        this.currentTime = currentTime;
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

    public String getRfaOverride() {
        return rfaOverride;
    }

    public Optional<String> getPreviousTeam() {
        return Optional.ofNullable(previousTeam);
    }

    public long getCurrentTime() {
        return currentTime;
    }
}
