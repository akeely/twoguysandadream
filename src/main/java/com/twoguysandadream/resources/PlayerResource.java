package com.twoguysandadream.resources;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.twoguysandadream.core.Player;
import com.twoguysandadream.core.PlayerRepository;

@RequestMapping("/api/league/{leagueId}/player")
@RestController
public class PlayerResource {

    private final PlayerRepository playerRepository;

    @Autowired
    public PlayerResource(PlayerRepository playerRepository) {
        this.playerRepository = playerRepository;
    }

    @GetMapping(params = "available=true")
    public List<Player> getAvailablePlayers(@PathVariable long leagueId) {

        return playerRepository.findAllAvailable(leagueId);
    }
}
