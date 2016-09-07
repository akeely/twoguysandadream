package com.twoguysandadream.api.legacy;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.Bid;
import com.twoguysandadream.core.Position;
import com.twoguysandadream.core.RosteredPlayer;
import com.twoguysandadream.core.Team;
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
    }

    @JsonProperty("PLAYERS")
    public Map<Long,Map<String,Object>> getAuctionPlayers() {

        return league.getAuctionBoard().stream()
            .collect(Collectors.toMap((b) -> b.getPlayer().getId(), (b) -> {
                    Map<String, Object> bid = new HashMap<>();
                    bid.put("RFA_PREV_OWNER", b.getPreviousTeam().orElse("NA"));
                    bid.put("NAME", b.getPlayer().getName());
                    bid.put("TIME", getExpirationTime(b));
                    bid.put("BIDDER", b.getTeam());
                    bid.put("TARGET", 0);
                    bid.put("TEAM", b.getPlayer().getRealTeam());
                    bid.put("BID", b.getAmount());
                    bid.put("POS", getPositionString(b.getPlayer().getPositions()));
                    return bid;
                }));
    }

    private Object getExpirationTime(Bid bid) {

        return Optional.of(bid)
            .map(b -> toRfaWait(b))
            .filter(b -> !league.isPaused())
            .orElse("PAUSED");
    }

    private Object toRfaWait(Bid bid) {

        if (bid.getExpirationTime() < bid.getCurrentTime() && "WAIT".equals(bid.getRfaOverride())) {
            return "WAIT";
        }

        return bid.getExpirationTime();
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
    public Map<String,Statistics> getTeamStatistics() {

        return league.getTeamStatistics().entrySet().stream()
            .collect(Collectors.toMap((e) -> e.getKey().getName(),
                (e) -> new Statistics(e.getValue()),
                (s,a) -> s,
                () -> new TreeMap<>()));
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

    @JsonProperty("RFA")
    public Map<String, Map<String, String>> getRfaResults() {

        Map<String, Map<String, String>> rfaResults = new HashMap<>();

        Map<Team, Collection<RosteredPlayer>> rosters = league.getRosters();
        for (Team team : rosters.keySet()) {
            List<RosteredPlayer> rfaPlayers = rosters.get(team).stream()
                .filter(r -> !"NA".equals(r.getRfaOverride()))
                .collect(Collectors.toList());

            for (RosteredPlayer player : rfaPlayers) {
                Map<String, String> result = new HashMap<>();
                result.put("TEAM", team.getName());
                result.put("PRICE", player.getCost().toPlainString());
                result.put("OVERRIDE", player.getRfaOverride());

                rfaResults.put(player.getPlayer().getName(), result);
            }
        }

        return rfaResults;
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
