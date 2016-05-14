package com.twoguysandadream.controller;


import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.MissingResourceException;
import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import com.twoguysandadream.security.NotRegisteredException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Controller
public class AuctionController {

    private final LeagueRepository leagueRepository;
    private final PlayerRepository playerRepository;
    private final AuctionUserRepository auctionUserRepository;
    private final TeamRepository teamRepository;

    @Autowired
    public AuctionController(LeagueRepository leagueRepository, PlayerRepository playerRepository,
        AuctionUserRepository auctionUserRepository, TeamRepository teamRepository) {
        this.leagueRepository = leagueRepository;
        this.playerRepository = playerRepository;
        this.auctionUserRepository = auctionUserRepository;
        this.teamRepository = teamRepository;
    }

    @RequestMapping("/login")
    public String login() {

        return "login";
    }


    @RequestMapping(method = RequestMethod.GET, path = "/league/{leagueId}/auction")
    public ModelAndView auctionBoard(@PathVariable long leagueId, @AuthenticationPrincipal
        AuctionUser user) throws MissingResourceException {

        ModelAndView mav = new ModelAndView("auction");
        League league = leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
        long teamId = auctionUserRepository.findTeamId(toUserId(user), leagueId)
            .orElseThrow(() -> new MissingResourceException("team for user: " + user.getUsername()));

        mav.addObject("leagueId", leagueId);
        mav.addObject("teamId", teamId);
        mav.addObject("league", league);
        mav.addObject("user", user);
        return mav;
    }

    @RequestMapping(method = RequestMethod.GET, path = "/league/{leagueId}/results")
    public ModelAndView draftResults(@PathVariable long leagueId, @AuthenticationPrincipal AuctionUser user)
        throws MissingResourceException {

        ModelAndView mav = new ModelAndView("draftResults");
        League league = leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
        long teamId = auctionUserRepository.findTeamId(toUserId(user), leagueId)
            .orElseThrow(() -> new MissingResourceException("team for user: " + user.getUsername()));

        List<WonPlayer> players = league.getRosters().entrySet().stream()
            .flatMap((e) -> e.getValue().stream().map((p) -> new WonPlayer(e.getKey(), p)))
            .collect(Collectors.toList());

        mav.addObject("leagueId", leagueId);
        mav.addObject("teamId", teamId);
        mav.addObject("players", players);

        return mav;
    }

    @RequestMapping(method = RequestMethod.GET, path = "/league/{leagueId}/availableplayers")
    public ModelAndView addPlayer(@PathVariable long leagueId, @AuthenticationPrincipal AuctionUser user)
        throws MissingResourceException {

        ModelAndView mav = new ModelAndView("addPlayer");
        League league = leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
        long teamId = auctionUserRepository.findTeamId(toUserId(user), leagueId)
            .orElseThrow(() -> new MissingResourceException("team for user: " + user.getUsername()));

        List<Player> players = playerRepository.findAllAvailable(leagueId);
        Team team = teamRepository.findOne(leagueId, teamId)
            .orElseThrow(() -> new MissingResourceException("team: " + teamId));

        mav.addObject("leagueId", leagueId);
        mav.addObject("teamId", teamId);
        mav.addObject("players", players);
        mav.addObject("team", team);

        return mav;
    }

    @RequestMapping(method = RequestMethod.GET, path = "/registration")
    public ModelAndView registration() {

        return new ModelAndView("registration");
    }

    @RequestMapping(method = RequestMethod.POST, path = "/registration", params = {"username", "passwd"})
    public String linkUser(@RequestParam("username") String username, @RequestParam("passwd") String passwd,
        @AuthenticationPrincipal AuctionUser user) {

        return "redirect:/";
    }

    @RequestMapping(method = RequestMethod.POST, path = "/registration")
    public String registerNewUser(@RequestParam("openIdToken") String token) {

        auctionUserRepository.findOrCreate(token);

        return "redirect:/";
    }

    private long toUserId(AuctionUser user) {

        return user.getId().orElseThrow(() -> new NotRegisteredException(user.getUsername()));
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
