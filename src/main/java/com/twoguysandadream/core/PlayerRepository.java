package com.twoguysandadream.core;

import java.util.List;
import java.util.Optional;

public interface PlayerRepository {

    Optional<Player> findOne(long playerId);

    List<Player> findAllAvailable(long leagueId);
}
