package com.twoguysandadream.core;

import java.util.Optional;

/**
 * Created by andrewk on 3/12/15.
 */
public interface LeagueRepository {

    public Optional<League> findOneByName(String name);
}
