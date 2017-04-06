package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.util.Optional;
import java.util.OptionalLong;
import java.util.concurrent.TimeUnit;

/**
 * Created by andrewk on 2/27/16.
 */
public class LeagueSettings {

    private final int rosterSize;
    private final BigDecimal budget;
    private final BigDecimal minimumBid = new BigDecimal("0.5");

    private final long auctionLength;
    private final long bidTimeExtension;
    private final long bidTimeBuffer;


    /**
     * @param rosterSize The number of players on a team.
     * @param budget The total amount that a team can spend.
     * @param auctionLength The amount of time before a new auction expires.
     * @param bidTimeExtension The amount of time to extend the auction to when a new bid is made.
     * @param bidTimeBuffer The time window when the remaining auction time should be modified.
     */
    public LeagueSettings(int rosterSize, BigDecimal budget, long auctionLength, long bidTimeExtension,
        long bidTimeBuffer) {

        this.rosterSize = rosterSize;
        this.budget = budget;
        this.auctionLength = toMillis(auctionLength);
        this.bidTimeExtension = toMillis(bidTimeExtension);
        this.bidTimeBuffer = toMillis(bidTimeBuffer);
    }

    public int getRosterSize() {
        return rosterSize;
    }

    public BigDecimal getBudget() {
        return budget;
    }

    public BigDecimal getMinimumBid() {
        return minimumBid;
    }

    public long getExpirationTime(Long existingExpirationTime) {

        long currentTime = System.currentTimeMillis();

        if (existingExpirationTime < currentTime + bidTimeBuffer) {
            return currentTime + bidTimeExtension;
        }

        return existingExpirationTime;
    }

    public long getExpirationTime() {
        return System.currentTimeMillis() + auctionLength;
    }

    private long toMillis(long minutes) {
        return TimeUnit.MILLISECONDS.convert(minutes, TimeUnit.MINUTES);
    }
}
