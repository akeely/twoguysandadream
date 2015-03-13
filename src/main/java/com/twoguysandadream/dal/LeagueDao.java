package com.twoguysandadream.dal;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;

import java.util.Optional;

/**
 * Created by andrewk on 3/13/15.
 */
public class LeagueDao implements LeagueRepository {

    @Override public Optional<League> findOneByName(String name) {
        return Optional.empty();
    }
}
