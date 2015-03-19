package com.twoguysandadream.resources.legacy;

import com.twoguysandadream.core.*;
import com.twoguysandadream.resources.InvalidArgumentException;
import com.twoguysandadream.resources.MissingResourceException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import javax.swing.text.html.Option;
import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Created by andrew_keely on 2/10/15.
 */
@Controller
@RequestMapping("/legacy/auction")
public class AuctionBoard {

    private final LeagueRepository leagueRepository;

    @Autowired
    public AuctionBoard(LeagueRepository leagueRepository) {

        this.leagueRepository = leagueRepository;
    }

    @RequestMapping("/league/{leagueName}")
    @ResponseBody
    public com.twoguysandadream.api.legacy.League checkBids(@PathVariable String leagueName,
        @RequestParam("playerids") String playerIdsString)
        throws IOException, MissingResourceException, InvalidArgumentException {

        Optional<League> league = leagueRepository.findOneByName(leagueName);

        league.ifPresent((l) -> {
            List<Long> existingPlayerIds = getPlayerIds(playerIdsString);
            addMissingPlayers(existingPlayerIds, l);
        });
        return new com.twoguysandadream.api.legacy.League(league.orElseThrow(
            ()-> new MissingResourceException("[league="+leagueName+"]")));
    }

    private void addMissingPlayers(List<Long> existingPlayerIds, League league) {

        List<Long> auctionBoardPlayers = league.getAuctionBoard().stream()
            .map((b) -> b.getPlayer().getId())
            .collect(Collectors.toList());

        existingPlayerIds.stream()
            .filter((p) -> !auctionBoardPlayers.contains(p))
            .map((p) -> getPlayerWon(p, league))
            .filter(Optional::isPresent)
            .map(Optional::get)
            .map(this::rosteredPlayerToBid)
            .forEach((b) -> league.getAuctionBoard().add(b));
    }

    private List<Long> getPlayerIds(String playerIdsString) throws InvalidArgumentException {

        if(StringUtils.isEmpty(playerIdsString)) {
            return Collections.emptyList();
        }

        String[] playerIdStrings = playerIdsString.split(";");

        try {
            return Arrays.asList(playerIdsString).stream().filter((s) -> !StringUtils.isEmpty(s))
                .map(Long::parseLong).collect(Collectors.toList());
        }
        catch(NumberFormatException e) {
            throw new InvalidArgumentException("playerIds must be numbers separated by ';'.", e);
        }
    }

    private Optional<Map.Entry<Team,RosteredPlayer>> getPlayerWon(Long playerId, League league) {

        return league.getRosters().entrySet().stream()
            .filter((e) ->
                e.getValue().stream()
                    .map((p) -> p.getPlayer().getId())
                    .anyMatch((p) -> p == playerId)
            )
            .map((e) -> toMapEntry(e.getKey(),
                e.getValue().stream()
                .filter((p) -> p.getPlayer().getId() == playerId)
                .findAny().get()))
            .findAny();

    }

    private Bid rosteredPlayerToBid(Map.Entry<Team,RosteredPlayer> player) {

        return new Bid(player.getKey().getName(), player.getValue().getPlayer(),
            player.getValue().getCost(), -1L);
    }

    private <K,V> Map.Entry<K,V> toMapEntry(K key, V value) {

        return new AbstractMap.SimpleEntry<K,V>(key, value);
    }
}
