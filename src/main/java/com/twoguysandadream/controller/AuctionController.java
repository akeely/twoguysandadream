package com.twoguysandadream.controller;


import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.MissingResourceException;
import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.OptionalLong;
import java.util.stream.Collectors;

@Controller
public class AuctionController {

    private final LeagueRepository leagueRepository;
    private final PlayerRepository playerRepository;
    private final AuctionUserRepository auctionUserRepository;

    @Autowired
    public AuctionController(LeagueRepository leagueRepository, PlayerRepository playerRepository,
        AuctionUserRepository auctionUserRepository) {
        this.leagueRepository = leagueRepository;
        this.playerRepository = playerRepository;
        this.auctionUserRepository = auctionUserRepository;
    }

    @RequestMapping("/login")
    public String login() {

        return "login";
    }


    @RequestMapping("/league/{leagueId}/auction")
    public ModelAndView auctionBoard(@PathVariable long leagueId, @AuthenticationPrincipal
        AuctionUser user) throws MissingResourceException {

        ModelAndView mav = new ModelAndView("auction");
        Optional<League> league = leagueRepository.findOne(leagueId);
        league.orElseThrow(() -> new MissingResourceException("league: " + leagueId));

        mav.addObject("league", league.get());
        mav.addObject("user", user);
        return mav;
    }

    @RequestMapping("/league/{leagueId}/results")
    public ModelAndView draftResults(@PathVariable long leagueId, @AuthenticationPrincipal AuctionUser user)
        throws MissingResourceException {

        ModelAndView mav = new ModelAndView("draftResults");
        League league = leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league: " + leagueId));

        List<WonPlayer> players = league.getRosters().entrySet().stream()
            .flatMap((e) -> e.getValue().stream().map((p) -> new WonPlayer(e.getKey(), p)))
            .collect(Collectors.toList());

        mav.addObject("players", players);

        return mav;
    }

    @RequestMapping("/league/{leagueId}/availableplayers")
    public ModelAndView addPlayer(@PathVariable long leagueId, @AuthenticationPrincipal AuctionUser user)
        throws MissingResourceException {

        ModelAndView mav = new ModelAndView("addPlayer");
        League league = leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
        long teamId = auctionUserRepository.findTeamId(user, leagueId)
            .orElseThrow(() -> new MissingResourceException("team for user: " + user.getUsername()));

        List<Player> players = playerRepository.findAllAvailable(leagueId);
        TeamStatistics stats = league.getTeamStatistics().entrySet().stream()
            .filter((t) -> t.getKey().getId() == teamId)
            .map(Map.Entry::getValue)
            .findAny()
            .orElseThrow(() -> new MissingResourceException("stats for team: " + teamId));

        mav.addObject("players", players);
        mav.addObject("adds", stats.getAdds());

        return mav;
    }

    private static class WonPlayer {

        private final Team team;
        private final RosteredPlayer player;


        private WonPlayer(Team team, RosteredPlayer player) {
            this.team = team;
            this.player = player;
        }

        public Team getTeam() {
            return team;
        }

        public RosteredPlayer getPlayer() {
            return player;
        }
    }
}
