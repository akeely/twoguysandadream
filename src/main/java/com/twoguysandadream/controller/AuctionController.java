package com.twoguysandadream.controller;


import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.AuthorizationException;
import com.twoguysandadream.resources.MissingResourceException;
import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;
import com.twoguysandadream.security.NotRegisteredException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.Stream;

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

    /**
     * Handle any request that is not handled by other controllers. This should handle all requests that are not
     * API requests and logon requests.
     */
    @GetMapping({"/", "/league/**"})
    public String home() {
        return "index";
    }

    @RequestMapping("/login")
    public String login() {

        return "login";
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
}
