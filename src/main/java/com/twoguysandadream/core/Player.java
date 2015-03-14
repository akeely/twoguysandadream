package com.twoguysandadream.core;

import java.util.Collection;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Player {

    private final long id;
    private final String name;
    private final Collection<Position> positions;
    private final String realTeam;

    public Player(long id, String name, Collection<Position> positions, String realTeam) {
        this.id = id;
        this.name = name;
        this.positions = positions;
        this.realTeam = realTeam;
    }

    public long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public Collection<Position> getPositions() {
        return positions;
    }

    public String getRealTeam() {
        return realTeam;
    }
}
