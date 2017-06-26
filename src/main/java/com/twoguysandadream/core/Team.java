package com.twoguysandadream.core;

import java.math.BigDecimal;
import java.util.Collection;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Team {

    private final long id;
    private final String name;
    private final Collection<RosteredPlayer> roster;
    private final BigDecimal budgetAdjustment;
    private final int adds;
    private final boolean isCommissioner;

    /**
     *  @param id
     * @param name
     * @param roster The players on this team, with the cost of the player.
     * @param budgetAdjustment
     * @param adds
     * @param isCommissioner
     */
    public Team(long id, String name, Collection<RosteredPlayer> roster, BigDecimal budgetAdjustment, int adds,
            boolean isCommissioner) {

        this.id = id;
        this.name = name;
        this.roster = roster;
        this.budgetAdjustment = budgetAdjustment;
        this.adds = adds;
        this.isCommissioner = isCommissioner;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Collection<RosteredPlayer> getRoster() {
        return roster;
    }

    public BigDecimal getBudgetAdjustment() {
        return budgetAdjustment;
    }

    public int getAdds() {
        return adds;
    }

    public boolean isCommissioner() {
        return isCommissioner;
    }
}
