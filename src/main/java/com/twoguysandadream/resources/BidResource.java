package com.twoguysandadream.resources;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.security.AuctionUser;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league/{leagueId}/bid")
public class BidResource {

    private static final Logger LOGGER = LoggerFactory.getLogger(BidResource.class);

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
            .map(this::getActiveBids)
            .orElseThrow(() -> new MissingResourceException("league [" + leagueId + "]"));
    }

    @RequestMapping(method = RequestMethod.POST, value = "/{playerId}")
    public void createBid(@PathVariable("leagueId") long leagueId, @PathVariable("playerId") long playerId,
        @RequestBody NewBid amount, @AuthenticationPrincipal AuctionUser user) {

        LOGGER.info("Submitting bid of ${} for {} by {} ({}).", amount.amount, playerId, user.getUsername(),
            user.getId());
    }

    private List<Bid> getActiveBids(League league) {

        return league.getAuctionBoard().stream()
            .filter(b -> b.getSecondsRemaining() > 0)
            .collect(Collectors.toList());
    }

    private static class NewBid {

        private final BigDecimal amount;

        @JsonCreator
        NewBid(@JsonProperty("amount") BigDecimal amount) {
            this.amount = amount;
        }
    }
}
