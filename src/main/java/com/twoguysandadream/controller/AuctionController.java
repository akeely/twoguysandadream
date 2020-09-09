package com.twoguysandadream.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.User;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.google.common.base.Strings;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.PlayerRepository;
import com.twoguysandadream.core.TeamRepository;
import com.twoguysandadream.security.AuctionUser;
import com.twoguysandadream.security.AuctionUserRepository;

@Controller
public class AuctionController {

    private final AuctionUserRepository auctionUserRepository;

    @Value("${javascript.url}")
    private String javascriptUrl;

    @Value("${css.url:}")
    private String cssUrl;

    @Autowired
    public AuctionController(AuctionUserRepository auctionUserRepository) {
        this.auctionUserRepository = auctionUserRepository;
    }

    /**
     * Handle any request that is not handled by other controllers. This should handle all requests that are not
     * API requests and logon requests.
     */
    @GetMapping({"/", "/league/**"})
    public String home(Model model) {

        model.addAttribute("javascriptUrl", javascriptUrl);
        if (!Strings.isNullOrEmpty(cssUrl)) {
            model.addAttribute("cssUrl", cssUrl);
        }

        return "index";
    }

    @GetMapping("/me")
    @ResponseBody
    public String me(@AuthenticationPrincipal User user) {

        if (user == null) {
            return "not found";
        }
        return user.getUsername();
    }

    @GetMapping("/login")
    public String login() {

        return "login";
    }

    @RequestMapping(method = RequestMethod.POST, path = "/registration")
    public String registerNewUser(@RequestParam("openIdToken") String token) {

        auctionUserRepository.findOrCreate(token);

        return "redirect:/";
    }
}
