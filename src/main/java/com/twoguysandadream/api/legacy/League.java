package com.twoguysandadream.api.legacy;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.Position;
import com.twoguysandadream.core.TeamStatistics;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Created by andrewk on 3/12/15.
 */
public class League {

    private final com.twoguysandadream.core.League league;

    public League(com.twoguysandadream.core.League league) {

        this.league = league;
        this.auctionPlayers = getAuctionPlayers();
        this.teamStatistics = getTeamStatistics();
    }

    @JsonProperty("PLAYERS")
    private Map<Long,Map<String,Object>> auctionPlayers;

    private Map<Long,Map<String,Object>> getAuctionPlayers() {

        return league.getAuctionBoard().stream()
            .collect(Collectors.toMap(
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
                bid.put("POS", getPositionString(b.getPlayer().getPositions()));
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

                        player.put("PRICE", r.getCost());
                        player.put("NAME", r.getPlayer().getName());
                        player.put("POS", getPositionString(r.getPlayer().getPositions()));

                        return player;
                    })
                    .collect(Collectors.toList());
                return toMapEntry(entry.getKey().getName(), roster);
            })
            .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));

    }

    @JsonProperty("TEAMS")
    private Map<String, Statistics> teamStatistics;

    private Map<String,Statistics> getTeamStatistics() {

        return league.getTeamStatistics().entrySet().stream()
            .collect(Collectors.toMap((e) -> e.getKey().getName(),
                (e) -> new Statistics(e.getValue())));
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

    private String getPositionString(Collection<Position> positions) {

        return positions.stream()
            .map(Position::toString)
            .collect(Collectors.joining("|"));
    }

    public static class Statistics {

        private final TeamStatistics statistics;

        public Statistics(TeamStatistics statistics) {
            this.statistics = statistics;
        }

        @JsonProperty("SPOTS")
        public int getOpenRosterSpots() {
            return statistics.getOpenRosterSpots();
        }

        @JsonProperty("MAX_BID")
        public BigDecimal getMaxBid() {
            return statistics.getMaxBid();
        }

        @JsonProperty("MONEY")
        public BigDecimal getAvailableBudget() {
            return statistics.getAvailableBudget();
        }

        @JsonProperty("ADDS")
        public int getAdds() {
            return statistics.getAdds();
        }
    }
}
