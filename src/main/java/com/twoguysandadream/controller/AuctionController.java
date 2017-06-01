package com.twoguysandadream.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.PlayerRepository;
import com.twoguysandadream.core.TeamRepository;
import com.twoguysandadream.security.AuctionUserRepository;

@Controller
public class AuctionController {
    
    private final LeagueRepository leagueRepository;
    private final PlayerRepository playerRepository;
    private final AuctionUserRepository auctionUserRepository;
    private final TeamRepository teamRepository;

    @Value("${javascript.url}")
    private String javascriptUrl;

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
    public String home(Model model) {

        model.addAttribute("javascriptUrl", javascriptUrl);

        return "index";
    }

    @RequestMapping("/login")
    public String login() {

        return "login";
    }

    @RequestMapping(method = RequestMethod.POST, path = "/registration")
    public String registerNewUser(@RequestParam("openIdToken") String token) {

        auctionUserRepository.findOrCreate(token);

        return "redirect:/";
    }
}
