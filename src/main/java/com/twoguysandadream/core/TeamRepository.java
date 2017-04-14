package com.twoguysandadream.core;

import java.util.List;
import java.util.Optional;

/**
 * Created by andrewk on 3/13/16.
 */
public interface TeamRepository {

    List<Team> findAll(long leagueId);

    Optional<Team> findOne(long leagueId, long teamId);

    Optional<Team> findByOwner(long leagueId, long ownerId);

    void update(long leagueId, Team team);
}
