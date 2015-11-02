package com.twoguysandadream.controller;


import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.MissingResourceException;
import com.twoguysandadream.security.AuctionUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.servlet.ModelAndView;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

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

    @RequestMapping("/auction")
    public String auction() {

        return "auction";
    }

    @RequestMapping("/league/{leagueName}/auction")
    public ModelAndView auctionBoard(@PathVariable String leagueName, @AuthenticationPrincipal
        AuctionUser user) throws MissingResourceException {

        ModelAndView mav = new ModelAndView("auction");
        Optional<League> league = leagueRepository.findOneByName(leagueName);
        league.orElseThrow(() -> new MissingResourceException("league: " + leagueName));

        mav.addObject("league", league.get());
        mav.addObject("user", user);
        return mav;
    }
}
