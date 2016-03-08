package com.twoguysandadream.controller;


import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.MissingResourceException;
import com.twoguysandadream.security.AuctionUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Controller
public class AuctionController {

    private final LeagueRepository leagueRepository;

    @Autowired
    public AuctionController(LeagueRepository leagueRepository) {
        this.leagueRepository = leagueRepository;
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
