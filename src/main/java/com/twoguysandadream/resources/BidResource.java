package com.twoguysandadream.resources;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.BidService;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.exception.BidException;
import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import com.twoguysandadream.security.NotRegisteredException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league/{leagueId}/bid")
public class BidResource {

    private static final Logger LOGGER = LoggerFactory.getLogger(BidResource.class);

    private final LeagueRepository leagueRepository;
    private final AuctionUserRepository userRepository;
    private final BidService bidService;

    @Autowired
    public BidResource(LeagueRepository leagueRepository, AuctionUserRepository userRepository, BidService bidService) {

        this.leagueRepository = leagueRepository;
        this.userRepository = userRepository;
        this.bidService = bidService;
    }

    @RequestMapping(method = RequestMethod.GET)
    public List<Bid> findOpenBids(@PathVariable("leagueId") long leagueId)
        throws MissingResourceException {

        Optional<League> league = leagueRepository.findOne(leagueId);

        return league
            .map(this::getActiveBids)
            .orElseThrow(() -> new MissingResourceException("league [" + leagueId + "]"));
    }

    @RequestMapping(method = RequestMethod.PUT, value = "/{playerId}")
    public void updateBid(@PathVariable("leagueId") long leagueId, @PathVariable("playerId") long playerId,
        @RequestBody NewBid amount, @AuthenticationPrincipal AuctionUser user)
        throws BidException, MissingResourceException {

        LOGGER.info("Submitting bid of ${} for {} by {} ({}).", amount.amount, playerId, user.getUsername(),
            user.getId());

        long teamId = getTeam(user, leagueId);
        bidService.acceptBid(leagueId, teamId, playerId, amount.amount);
    }

    @RequestMapping(method = RequestMethod.POST)
    public void addPlayer(@PathVariable("leagueId") long leagueId, @RequestBody PlayerAddition addition,
        @RequestParam(name = "commissioner", required = false, defaultValue = "false") boolean isCommisioner,
        @AuthenticationPrincipal AuctionUser user) throws BidException, MissingResourceException {

        long teamId = getTeam(user, leagueId);

        if (isCommisioner) {
            bidService.addPlayerAsCommisioner(leagueId, teamId, addition.playerId);
        } else {
            bidService.addPlayer(leagueId, teamId, addition.playerId);
        }
    }

    private List<Bid> getActiveBids(League league) {

        return league.getAuctionBoard().stream()
            .filter(b -> b.getSecondsRemaining() > 0 || league.isPaused())
            .collect(Collectors.toList());
    }

    private long getTeam(AuctionUser user, long leagueId) throws MissingResourceException {

        return userRepository.findTeamId(toTeamId(user), leagueId)
            .orElseThrow(() -> new MissingResourceException("team [" + "-" + user.getId() + "-" +leagueId + "]"));
    }

    private long toTeamId(AuctionUser user) {
        return user.getId().orElseThrow(() -> new NotRegisteredException(user.getUsername()));
    }

    private static class NewBid {

        private final BigDecimal amount;

        @JsonCreator
        NewBid(@JsonProperty("amount") BigDecimal amount) {
            this.amount = amount;
        }
    }

    private static class PlayerAddition {

        private final long playerId;

        @JsonCreator
        private PlayerAddition(@JsonProperty("playerId") long playerId) {
            this.playerId = playerId;
        }

        public long getPlayerId() {
            return playerId;
        }
    }
}
