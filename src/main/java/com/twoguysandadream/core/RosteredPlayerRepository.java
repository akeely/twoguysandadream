package com.twoguysandadream.core;

public interface RosteredPlayerRepository {

    void save(long leagueId, long teamId, RosteredPlayer player);
}
