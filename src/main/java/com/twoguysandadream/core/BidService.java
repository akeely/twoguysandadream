package com.twoguysandadream.core;

import com.twoguysandadream.core.exception.AuctionExpiredException;
import com.twoguysandadream.core.exception.BidException;
import com.twoguysandadream.core.exception.InsufficientBidException;
import com.twoguysandadream.core.exception.InsufficientFundsException;
import com.twoguysandadream.core.exception.RosterFullException;
import com.twoguysandadream.resources.AuthorizationException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Map;
import java.util.Optional;

@Service
public class BidService {

    private static final Logger LOG = LoggerFactory.getLogger(BidService.class);

    private static final BigDecimal INITIAL_BID = new BigDecimal("0.5");

    private final LeagueRepository leagueRepository;
    private final BidRepository bidRepository;
    private final PlayerRepository playerRepository;
    private final TeamRepository teamRepository;
    private final RosteredPlayerRepository rosteredPlayerRepository;

    @Autowired
    public BidService(LeagueRepository leagueRepository, BidRepository bidRepository, PlayerRepository playerRepository,
        TeamRepository teamRepository, RosteredPlayerRepository rosteredPlayerRepository) {

        this.leagueRepository = leagueRepository;
        this.bidRepository = bidRepository;
        this.playerRepository = playerRepository;
        this.teamRepository = teamRepository;
        this.rosteredPlayerRepository = rosteredPlayerRepository;
    }

    public void acceptBid(long leagueId, long teamId, long playerId, BigDecimal amount) throws BidException {

        League league = leagueRepository.findOne(leagueId).orElseThrow(
            () -> new IllegalArgumentException("No league with id " + leagueId));

        Team team = league.getTeams().stream().filter((t) -> t.getId() == teamId).findFirst()
            .orElseThrow(() -> new IllegalArgumentException("No team " + teamId + " exists in league " + leagueId));

        Bid existingBid = league.getAuctionBoard().stream().filter((b) -> b.getPlayer().getId() == playerId)
            .findAny().orElseThrow(() -> new AuctionExpiredException(playerId));

        checkExpired(existingBid);
        validateRosterSpace(team, existingBid, league);
        validateBid(existingBid, amount);
        validateFunds(league, team, existingBid, amount);

        long expirationTime = getExpirationTime(league, existingBid);
        Bid newBid = new Bid(teamId, team.getName(), existingBid.getPlayer(), amount, expirationTime);

        LOG.info("Saving successful bid of ${} for {} by {}.", amount, newBid.getPlayer().getName(), newBid.getTeam());
        bidRepository.save(leagueId, newBid);
    }

    public void addPlayer(long leagueId, long teamId, long playerId) throws BidException {

        League league = leagueRepository.findOne(leagueId).orElseThrow(
            () -> new IllegalArgumentException("No league with id " + leagueId));

        Team team = league.getTeams().stream().filter((t) -> t.getId() == teamId).findFirst()
            .orElseThrow(() -> new IllegalArgumentException("No team " + teamId + " exists in league " + leagueId));

        validateAvailable(league, playerId);
        validateRosterSpace(team, null, league);
        validateAdds(team);

        Bid bid = new Bid(teamId, team.getName(), getPlayer(playerId), INITIAL_BID,
            league.getSettings().getExpirationTime());

        bidRepository.create(leagueId, bid);
        removeAdd(leagueId, team);
    }

    @Scheduled(fixedRate = 100L)
    @Transactional
    public void clearExpired() {

        Map<Long, Collection<Bid>> openBids = bidRepository.findAll();
        for (Long leagueId : openBids.keySet()) {

            Optional<League> league = leagueRepository.findOne(leagueId);

            if (league
                    .filter(l -> l.getDraftStatus().equals(League.DraftStatus.OPEN))
                    .filter(l -> l.getDraftType().equals(League.DraftType.AUCTION))
                    .isPresent()) {

                openBids.get(leagueId).stream()
                        .filter(this::isExpired)
                        .forEach(b -> clearExpired(leagueId, b));
            }
            else {
                LOG.warn("Skipping expiration for league {} because draft status is {}.", leagueId,
                        league.map(League::getDraftStatusDescription).orElse("unknown."));
            }
        }
    }

    private void clearExpired(long leagueId, Bid bid) {

        Optional<Long> teamId = Optional.ofNullable(bid.getTeamId());
        teamId.flatMap(t -> teamRepository.findOne(leagueId, t)).ifPresent(t -> {
            LOG.info("{} won by {} for ${}.", bid.getPlayer().getName(), t.getName(), bid.getAmount());
            rosteredPlayerRepository.save(leagueId, t.getId(), toRosteredPlayer(bid));
            Team updated = new Team(t.getId(), t.getName(), t.getRoster(), t.getBudgetAdjustment(), t.getAdds() + 1,
                    t.isCommissioner());
            teamRepository.update(leagueId, updated);
        });

        bidRepository.remove(leagueId, bid.getPlayer().getId());
    }

    private boolean isExpired(Bid bid) {

        return bid.getExpirationTime() < System.currentTimeMillis();
    }

    private RosteredPlayer toRosteredPlayer(Bid bid) {

        return new RosteredPlayer(bid.getPlayer(), bid.getAmount());
    }

    private void removeAdd(long leagueId, Team team) {

        int adds = team.getAdds() - 1;
        Team updated = new Team(team.getId(), team.getName(), team.getRoster(), team.getBudgetAdjustment(), adds,
                team.isCommissioner());
        teamRepository.update(leagueId, updated);
    }

    public void addPlayerAsCommisioner(long leagueId, long teamId, long playerId) throws BidException {

        teamRepository.findOne(leagueId, teamId)
                .filter(Team::isCommissioner)
                .orElseThrow(() -> new AuthorizationException("Must be commissioner to add player as commissioner."));

        League league = leagueRepository.findOne(leagueId).orElseThrow(
            () -> new IllegalArgumentException("No league with id " + leagueId));

        validateAvailable(league, playerId);

        Bid bid = new Bid(null, null, getPlayer(playerId), BigDecimal.ZERO, league.getSettings().getExpirationTime());

        bidRepository.create(leagueId, bid);
    }

    private void validateAdds(Team team) {
        if (team.getAdds() < 1) {
            throw new IllegalStateException("Team " + team.getName() + " does not have any adds available.");
        }
    }

    private void validateAvailable(League league, long playerId) throws AuctionExpiredException {

        if (league.getAuctionBoard().stream()
                .anyMatch((b) -> b.getPlayer().getId() == playerId)) {

            throw new AuctionExpiredException(playerId);
        }

        if (league.getTeams().stream()
                .map(Team::getRoster)
                .flatMap(Collection::stream)
                .anyMatch((p) -> p.getPlayer().getId() == playerId)) {

            throw new AuctionExpiredException(playerId);
        }
    }

    private void validateRosterSpace(Team team, Bid existingBid, League league) throws RosterFullException {

        if (existingBid != null && existingBid.getTeamId() == team.getId()) {
            return;
        }

        int availableSpaces = league.getTeamStatistics().get(team.getId()).getOpenRosterSpots();
        long openBids = league.getAuctionBoard().stream().filter((b) -> b.getTeamId() == team.getId()).count();

        if (availableSpaces <= openBids) {
            throw new RosterFullException();
        }
    }

    private void checkExpired(Bid existingBid) throws AuctionExpiredException {

        if (isExpired(existingBid)) {
            throw new AuctionExpiredException(existingBid.getPlayer().getId());
        }
    }

    private void validateFunds(League league, Team team, Bid existingBid, BigDecimal amount)
        throws InsufficientFundsException {

        Map<Long, TeamStatistics> map = league.getTeamStatistics();
        TeamStatistics statistics = map.get(team.getId());
        BigDecimal adjustment = Optional.ofNullable(existingBid)
            .filter((b) -> b.getTeamId() == team.getId())
            .map(Bid::getAmount)
            .orElse(BigDecimal.ZERO);

        if (amount.compareTo(statistics.getMaxBid().subtract(adjustment)) > 0) {
            throw new InsufficientFundsException(amount, statistics.getMaxBid().subtract(adjustment));
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
