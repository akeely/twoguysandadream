package com.twoguysandadream.controller;


import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class AuctionController {

    @RequestMapping("/login")
    public String login() {

        return "login";
    }

    @RequestMapping("/auction")
    public String auction() {

        return "auction";
    }
}
