package com.twoguysandadream.core;

import java.util.Collection;

public class Player {

    private final long id;
    private final String name;
    private final Collection<Position> positions;
    private final String realTeam;
    private final int rank;

    public Player(long id, String name, Collection<Position> positions, String realTeam, int rank) {
        this.id = id;
        this.name = name;
        this.positions = positions;
        this.realTeam = realTeam;
        this.rank = rank;
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

    public int getRank() {
        return rank;
    }
}
