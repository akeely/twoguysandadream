package com.twoguysandadream.core;

import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * Created by andrewk on 2/27/16.
 */
public interface BidRepository {

    /**
     * Find all open bids for all leagues.
     *
     * @return All open bids, keyed on leagueId.
     */
    Map<Long, Collection<Bid>> findAll();
    List<Bid> findAll(long leagueId);
    void save(long leagueId, Bid bid);
    void create(long leagueId, Bid bid);
    void remove(long leagueId, long playerId);
}
