package com.twoguysandadream.core;

import java.util.Optional;

public interface PlayerRepository {

    Optional<Player> findOne(long playerId);
}
