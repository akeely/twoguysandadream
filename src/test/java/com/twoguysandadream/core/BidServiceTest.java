package com.twoguysandadream.core;


import com.google.common.collect.ImmutableList;
import com.twoguysandadream.core.exception.AuctionExpiredException;
import com.twoguysandadream.core.exception.InsufficientBidException;
import com.twoguysandadream.core.exception.InsufficientFundsException;
import com.twoguysandadream.core.exception.RosterFullException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

@RunWith(MockitoJUnitRunner.class)
public class BidServiceTest {

    private static final long LEAGUE_ID = 123;
    private static final long TEAM_ID = 111;
    private static final long PLAYER_ID = 321;

    private static final int ROSTER_SIZE = 10;
    private static final BigDecimal BUDGET = new BigDecimal("100");
    private static final BigDecimal MIN_BID = new BigDecimal("0.5");

    @Mock LeagueRepository leagueRepository;
    @Mock BidRepository bidRepository;
    @Mock PlayerRepository playerRepository;

    @InjectMocks private BidService bidService;

    @Test
    public void testAcceptBid() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = BigDecimal.TEN;

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);

        ArgumentCaptor<Bid> captor = ArgumentCaptor.forClass(Bid.class);
        verify(bidRepository).save(eq(LEAGUE_ID), captor.capture());

        assertEquals("Unexpected player bid on.", PLAYER_ID, captor.getValue().getPlayer().getId());
        assertEquals("Unexpected team making bid.", (Long) TEAM_ID, captor.getValue().getTeamId());
        assertEquals("Unexpected bid amount.", amount, captor.getValue().getAmount());
    }

    @Test
    public void testAcceptBid_under10Min() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("1.5");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);

        ArgumentCaptor<Bid> captor = ArgumentCaptor.forClass(Bid.class);
        verify(bidRepository).save(eq(LEAGUE_ID), captor.capture());

        assertEquals("Unexpected player bid on.", PLAYER_ID, captor.getValue().getPlayer().getId());
        assertEquals("Unexpected team making bid.", (Long) TEAM_ID, captor.getValue().getTeamId());
        assertEquals("Unexpected bid amount.", amount, captor.getValue().getAmount());
    }

    @Test
    public void testAcceptBid_over10Min() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.TEN, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("11");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);

        ArgumentCaptor<Bid> captor = ArgumentCaptor.forClass(Bid.class);
        verify(bidRepository).save(eq(LEAGUE_ID), captor.capture());

        assertEquals("Unexpected player bid on.", PLAYER_ID, captor.getValue().getPlayer().getId());
        assertEquals("Unexpected team making bid.", (Long) TEAM_ID, captor.getValue().getTeamId());
        assertEquals("Unexpected bid amount.", amount, captor.getValue().getAmount());
    }

    @Test(expected = InsufficientBidException.class)
    public void testAcceptBid_insufficient() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = BigDecimal.ONE;

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);
    }

    @Test(expected = InsufficientBidException.class)
    public void testAcceptBid_under10Insufficient() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("1.1");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);
    }

    @Test(expected = InsufficientBidException.class)
    public void testAcceptBid_over10Insufficient() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.TEN, future(60));

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("10.5");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);
    }

    @Test(expected = RosterFullException.class)
    public void testAcceptBid_rosterFull() throws Exception {

        List<RosteredPlayer> roster = IntStream.range(0, ROSTER_SIZE)
            .mapToObj(this::createPlayer)
            .map((p) -> new RosteredPlayer(p, BigDecimal.ONE))
            .collect(Collectors.toList());

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(roster, Collections.singletonList(bid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BigDecimal.TEN);
    }

    /**
     * Verify that if the current leading bids for a team would fill the roster, then the team cannot bid on another
     * player.
     */
    @Test(expected = RosterFullException.class)
    public void testAcceptBid_rosterFullWithOpenBids() throws Exception {

        List<RosteredPlayer> roster = IntStream.range(0, ROSTER_SIZE - 1)
            .mapToObj(this::createPlayer)
            .map((p) -> new RosteredPlayer(p, BigDecimal.ONE))
            .collect(Collectors.toList());

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));
        Bid teamsBid = createBid(PLAYER_ID + 1, TEAM_ID, BigDecimal.TEN, future(60));

        createLeague(roster, ImmutableList.of(bid, teamsBid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BigDecimal.TEN);
    }

    /**
     * Verify that if a current bid would fill a team's roster, that team can still increase the bid on a player that
     * player.
     */
    @Test
    public void testAcceptBid_rosterFullWithOpenBidsUpdateBid() throws Exception {

        List<RosteredPlayer> roster = IntStream.range(0, ROSTER_SIZE - 1)
            .mapToObj(this::createPlayer)
            .map((p) -> new RosteredPlayer(p, BigDecimal.ONE))
            .collect(Collectors.toList());

        Bid bid = createBid(PLAYER_ID + 1, 1, BigDecimal.ONE, future(60));
        Bid teamsBid = createBid(PLAYER_ID, TEAM_ID, BigDecimal.ONE, future(60));

        createLeague(roster, ImmutableList.of(bid, teamsBid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BigDecimal.TEN);
    }

    @Test(expected = InsufficientFundsException.class)
    public void testAcceptBid_insufficientFunds() throws Exception {

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), ImmutableList.of(bid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BUDGET.add(BigDecimal.ONE));
    }

    /**
     * Ensure that a team must reserve enough funds for all open roster spots.
     */
    @Test(expected = InsufficientFundsException.class)
    public void testAcceptBid_insufficientFundsOpenRosterSpots() throws Exception {

        BigDecimal reservedBudget = MIN_BID.multiply(new BigDecimal(ROSTER_SIZE - 1));

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), ImmutableList.of(bid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BUDGET.subtract(reservedBudget).add(MIN_BID));
    }

    /**
     * Verify the reserved funds for open roster spots is not too large.
     * @see #testAcceptBid_insufficientFundsOpenRosterSpots()
     */
    @Test
    public void testAcceptBid_sufficientFundsOpenRosterSpots() throws Exception {

        BigDecimal reservedBudget = MIN_BID.multiply(new BigDecimal(ROSTER_SIZE - 1));

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, future(60));

        createLeague(Collections.emptyList(), ImmutableList.of(bid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BUDGET.subtract(reservedBudget));
    }

    @Test
    public void testAcceptBid_noExtension() throws Exception {

        long expirationTime = future(70);

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, expirationTime);

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("1.5");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);

        ArgumentCaptor<Bid> captor = ArgumentCaptor.forClass(Bid.class);
        verify(bidRepository).save(eq(LEAGUE_ID), captor.capture());

        assertEquals("Unexpected expiration time.", expirationTime, captor.getValue().getExpirationTime());
    }

    @Test
    public void testAcceptBid_extendTime() throws Exception {

        long expirationTime = future(50);

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, expirationTime);

        createLeague(Collections.emptyList(), Collections.singletonList(bid));

        BigDecimal amount = new BigDecimal("1.5");

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, amount);

        ArgumentCaptor<Bid> captor = ArgumentCaptor.forClass(Bid.class);
        verify(bidRepository).save(eq(LEAGUE_ID), captor.capture());

        assertTrue("Expiration time should have been extended.",
            (captor.getValue().getExpirationTime() - future(60)) < 100);
    }

    @Test(expected = AuctionExpiredException.class)
    public void testAcceptBid_expired() throws Exception {

        long expirationTime = future(-1);

        Bid bid = createBid(PLAYER_ID, 1, BigDecimal.ONE, expirationTime);

        createLeague(Collections.emptyList(), ImmutableList.of(bid));

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BigDecimal.TEN);
    }

    @Test(expected = AuctionExpiredException.class)
    public void testAcceptBid_notAvailable() throws Exception {


        createLeague(Collections.emptyList(), Collections.emptyList());

        bidService.acceptBid(LEAGUE_ID, TEAM_ID, PLAYER_ID, BigDecimal.TEN);
    }

    private League createLeague(Collection<RosteredPlayer> roster, List<Bid> openBids) {

        LeagueSettings settings = createSettings();
        List<Team> teams = createTeams(roster);
        League league = new League(LEAGUE_ID, "leagueName", settings, openBids, teams);
        when(leagueRepository.findOne(LEAGUE_ID)).thenReturn(Optional.of(league));
        return league;
    }

    private LeagueSettings createSettings() {
        return new LeagueSettings(ROSTER_SIZE, BUDGET, 120, 60, 60);
    }

    private Bid createBid(long playerId, long teamId, BigDecimal amount, long time) {

        return new Bid(teamId, "teamName", createPlayer(playerId), amount, time);
    }

    private List<Team> createTeams(Collection<RosteredPlayer> roster) {
        Team team = new Team(TEAM_ID, "teamName", roster, BigDecimal.ZERO, 3);
        return Collections.singletonList(team);
    }

    private Player createPlayer(long id) {

        return new Player(id, "playerName", Collections.emptyList(), "realTeam", 1);
    }

    private long future(int seconds) {

        return System.currentTimeMillis() + TimeUnit.MILLISECONDS.convert(seconds, TimeUnit.SECONDS);
    }
}
