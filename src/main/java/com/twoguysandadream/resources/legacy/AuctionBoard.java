package com.twoguysandadream.resources.legacy;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.resources.MissingResourceException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.IOException;
import java.util.Optional;

/**
 * Created by andrew_keely on 2/10/15.
 */
@Controller
@RequestMapping("/legacy/auction")
public class AuctionBoard {

    @Autowired
    private LeagueRepository leagueRepository;

    @RequestMapping("/league/{leagueName}")
    @ResponseBody
    public com.twoguysandadream.api.legacy.League checkBids(@PathVariable String leagueName)
        throws IOException, MissingResourceException {

        Optional<League> league = leagueRepository.findOneByName(leagueName);

        return new com.twoguysandadream.api.legacy.League(league.orElseThrow(
            ()-> new MissingResourceException("[league="+leagueName+"]")));
    }
}
