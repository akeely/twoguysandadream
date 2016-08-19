package com.twoguysandadream.resources;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league")
public class LeagueResource {

    private final LeagueRepository leagueRepository;

    @Autowired
    public LeagueResource(LeagueRepository leagueRepository) {
        this.leagueRepository = leagueRepository;
    }

    @RequestMapping(method = RequestMethod.GET, path = "/{leagueId}")
    public League findOne(@PathVariable long leagueId) throws MissingResourceException {
        return leagueRepository.findOne(leagueId)
                .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
    }
}
