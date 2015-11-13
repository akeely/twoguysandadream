package com.twoguysandadream.resources;

import java.util.List;
import java.util.Optional;

import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league/{leagueId}/bid")
public class BidResource {

    private final LeagueRepository leagueRepository;

    @Autowired
    public BidResource(LeagueRepository leagueRepository) {

        this.leagueRepository = leagueRepository;
    }

    @RequestMapping
    public List<Bid> findOpenBids(@PathVariable("leagueId") long leagueId)
        throws MissingResourceException {

        Optional<League> league = leagueRepository.findOne(leagueId);

        return league
            .map(League::getAuctionBoard)
            .orElseThrow(() -> new MissingResourceException("league [" + leagueId + "]"));
    }
}
