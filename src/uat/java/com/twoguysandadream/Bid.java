package com.twoguysandadream;

import java.math.BigDecimal;

/**
 * Created by andrewk on 3/11/15.
 */
public class Bid {

    private final String team;
    private final String player;
    private final BigDecimal amount;

    public Bid(String team, String player, BigDecimal amount) {
        this.team = team;
        this.player = player;
        this.amount = amount.setScale(2, BigDecimal.ROUND_HALF_UP);
    }

    public Bid(String team, String player, String amountString) {

        this(team, player, stringToBigDecimal(amountString));
    }

    private static BigDecimal stringToBigDecimal(String string) {

        String s = string.replace("$","");
        return new BigDecimal(s);
    }

    @Override public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        Bid bid = (Bid) o;

        if (!amount.equals(bid.amount))
            return false;
        if (!player.equals(bid.player))
            return false;
        if (!team.equals(bid.team))
            return false;

        return true;
    }

    @Override public int hashCode() {
        int result = team.hashCode();
        result = 31 * result + player.hashCode();
        result = 31 * result + amount.hashCode();
        return result;
    }

    @Override public String toString() {
        return "Bid{" +
            "team='" + team + '\'' +
            ", player='" + player + '\'' +
            ", amount=" + amount +
            '}';
    }
}
