package com.twoguysandadream.core;

import com.twoguysandadream.core.exception.AuctionExpiredException;
import com.twoguysandadream.core.exception.BidException;
import com.twoguysandadream.core.exception.InsufficientBidException;
import com.twoguysandadream.core.exception.InsufficientFundsException;
import com.twoguysandadream.core.exception.RosterFullException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
public class BidService {

    private static final Logger LOG = LoggerFactory.getLogger(BidService.class);

    private final LeagueRepository leagueRepository;
    private final BidRepository bidRepository;
    private final PlayerRepository playerRepository;

    @Autowired
    public BidService(LeagueRepository leagueRepository, BidRepository bidRepository,
        PlayerRepository playerRepository) {

        this.leagueRepository = leagueRepository;
        this.bidRepository = bidRepository;
        this.playerRepository = playerRepository;
    }

    public void acceptBid(long leagueId, long teamId, long playerId, BigDecimal amount) throws BidException {

        League league = leagueRepository.findOne(leagueId).orElseThrow(
            () -> new IllegalArgumentException("No league with id " + leagueId));

        Team team = league.getTeamStatistics().keySet().stream().filter((t) -> t.getId() == teamId).findFirst()
            .orElseThrow(() -> new IllegalArgumentException("No team " + teamId + " exists in league " + leagueId));

        Bid existingBid = league.getAuctionBoard().stream().filter((b) -> b.getPlayer().getId() == playerId)
            .findAny().orElseThrow(() -> new AuctionExpiredException(playerId));

        checkExpired(existingBid);
        validateBid(existingBid, amount);
        validateFunds(league, team, existingBid, amount);
        validateRosterSpace(team, existingBid, league);

        long expirationTime = getExpirationTime(league, existingBid);
        Bid newBid = new Bid(teamId, team.getName(), existingBid.getPlayer(), amount, expirationTime);

        LOG.info("Saving successful bid of ${} for {} by {}.", amount, newBid.getPlayer().getName(), newBid.getTeam());
        bidRepository.save(leagueId, newBid);
    }

    private void validateRosterSpace(Team team, Bid existingBid, League league) throws RosterFullException {

        if (existingBid.getTeamId() == team.getId()) {
            return;
        }

        int availableSpaces = league.getTeamStatistics().get(team).getOpenRosterSpots();
        long openBids = league.getAuctionBoard().stream().filter((b) -> b.getTeamId() == team.getId()).count();

        if (availableSpaces <= openBids) {
            throw new RosterFullException();
        }
    }

    private void checkExpired(Bid existingBid) throws AuctionExpiredException {

        if (existingBid.getExpirationTime() < System.currentTimeMillis()) {
            throw new AuctionExpiredException(existingBid.getPlayer().getId());
        }
    }

    private void validateFunds(League league, Team team, Bid existingBid, BigDecimal amount)
        throws InsufficientFundsException {

        TeamStatistics statistics = league.getTeamStatistics().get(team);
        BigDecimal adjustment = Optional.of(existingBid)
            .filter((b) -> b.getTeamId() == team.getId())
            .map(Bid::getAmount)
            .orElse(BigDecimal.ZERO);

        if (amount.compareTo(statistics.getMaxBid().subtract(adjustment)) > 0) {
            throw new InsufficientFundsException(amount, statistics.getMaxBid());
        }
    }

    private void validateBid(Bid existingBid, BigDecimal amount) throws InsufficientBidException {

        BigDecimal minBid = new BigDecimal("0.5");
        if (existingBid.getAmount().compareTo(BigDecimal.TEN) >= 0) {
            minBid = BigDecimal.ONE;
        }

        if (existingBid.getAmount().add(minBid).compareTo(amount) > 0) {
            throw new InsufficientBidException(amount, existingBid.getAmount().add(minBid));
        }
    }

    private Player getPlayer(long playerId) {

        return playerRepository.findOne(playerId)
            .orElseThrow(() -> new IllegalArgumentException("No such player " + playerId));
    }

    private long getExpirationTime(League league, Bid existingBid) {

        return league.getSettings().getExpirationTime(existingBid.getExpirationTime());
    }
}