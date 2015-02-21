package com.twoguysandadream.core;

import java.util.Collection;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Player {

    private final long id;
    private final String name;
    private final Collection<Position> postitions;
    private final String realTeam;

    public Player(long id, String name, Collection<Position> postitions, String realTeam) {
        this.id = id;
        this.name = name;
        this.postitions = postitions;
        this.realTeam = realTeam;
    }
}
