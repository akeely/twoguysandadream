package com.twoguysandadream.api.legacy;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by andrewk on 3/12/15.
 */
public class League {

    private final com.twoguysandadream.core.League league;

    public League(com.twoguysandadream.core.League league) {

        this.league = league;
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

}
