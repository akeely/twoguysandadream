package com.twoguysandadream.core;

import java.util.List;

/**
 * Created by andrewk on 2/27/16.
 */
public interface BidRepository {

    List<Bid> findAll(long leagueId);
    void save(long leagueId, Bid bid);
}
