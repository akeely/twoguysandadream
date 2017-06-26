package com.twoguysandadream.core;

import java.util.Optional;

import com.twoguysandadream.resources.MissingResourceException;

/**
 * Created by andrewk on 3/12/15.
 */
public interface LeagueRepository {

    Optional<League> findOne(long id);
    Optional<League> findOneByName(String name);
    void updateDraftStatus(long id, League.DraftStatus newStatus) throws MissingResourceException;
}
