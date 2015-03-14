package com.twoguysandadream.api.legacy;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.Position;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.AbstractMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Created by andrewk on 3/12/15.
 */
public class League {

    private final com.twoguysandadream.core.League league;

    public League(com.twoguysandadream.core.League league) {

        this.league = league;
    }

    @JsonProperty("PLAYERS")
    public Map<Long,Map<String,Object>> getAuctionPlayers() {

        return league.getAuctionBoard().stream().collect(Collectors.toMap(
            (b)-> b.getPlayer().getId(),
            (b) -> {
                Map<String,Object> bid = new HashMap<>();
                bid.put("RFA_PREV_OWNER", "NA");
                bid.put("NAME", b.getPlayer().getName());
                bid.put("TIME", b.getExpirationTime());
                bid.put("BIDDER", b.getTeam());
                bid.put("TARGET", 0);
                bid.put("TEAM", b.getPlayer().getRealTeam());
                bid.put("BID", b.getAmount());
                bid.put("POS", b.getPlayer().getPositions().stream()
                    .map(Position::toString)
                    .collect(Collectors.joining("|")));
                return bid;
            }));
    }

    @JsonProperty("ROSTERS")
    public Map<String,List<Map<String,Object>>> getRosters() {

        return league.getRosters().entrySet().stream()
            .map((entry) -> {
                List<Map<String,Object>> roster = entry.getValue().stream()
                    .map((r) -> {
                        Map<String,Object> player = new HashMap<>();

                        return player;
                    })
                    .collect(Collectors.toList());
                return toMapEntry(entry.getKey().getName(), roster);
            })
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

    }

    @JsonProperty("TEAMS")
    public Map<String,Map<String,Object>> getTeamStatistics() {

        return league.getTeamStatistics().entrySet().stream()
            .map((e) -> {
                Map<String,Object> stats = new HashMap<>();
                stats.put("SPOTS", e.getValue().getOpenRosterSpots());
                stats.put("MAX_BID", e.getValue().getMaxBid());
                stats.put("MONEY", e.getValue().getAvailableBudget());
                stats.put("ADDS", e.getValue().getAdds());

                return toMapEntry(e.getKey().getName(), stats);
            })
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
    }

    @JsonProperty("TIME")
    public Map<String, Object> getCurrentTime() {

        Map<String, Object> currentTime = new HashMap<>();

        LocalDateTime time = LocalDateTime.now();

        currentTime.put("CURRENT_SECONDS", time.atZone(ZoneId.systemDefault()).toEpochSecond());
        currentTime.put("MONTH", String.format("%02d", time.getMonthValue()));
        currentTime.put("DAY", String.format("%02d", time.getDayOfMonth()));
        currentTime.put("HOUR", String.format("%02d", time.getHour()));
        currentTime.put("MINUTE", String.format("%02d", time.getMinute()));
        currentTime.put("SECOND", String.format("%02d", time.getSecond()));

        return currentTime;
    }

    private <K,V> Map.Entry<K,V> toMapEntry(K key, V value) {

        return new AbstractMap.SimpleEntry<K,V>(key, value);
    }
}
