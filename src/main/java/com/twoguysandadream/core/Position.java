package com.twoguysandadream.core;

/**
 * Created by andrew_keely on 2/20/15.
 */
public class Position {

    private final String name;

    public Position(String name) {

        this.name = name;
    }

    public String getName() {
        return name;
    }

    @Override public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;

        Position position = (Position) o;

        if (name != null ? !name.equals(position.name) : position.name != null)
            return false;

        return true;
    }

    @Override public int hashCode() {
        return name != null ? name.hashCode() : 0;
    }

    @Override public String toString() {
        return name;
    }
}
