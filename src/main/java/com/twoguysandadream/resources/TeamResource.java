package com.twoguysandadream.resources;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonProperty;
import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.RosteredPlayer;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamStatistics;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league/{leagueId}/team")
public class TeamResource {

    private final LeagueRepository leagueRepository;

    @Autowired
    public TeamResource(LeagueRepository leagueRepository) {
        this.leagueRepository = leagueRepository;
    }

    @RequestMapping
    public List<TeamDto> findAll(@PathVariable("leagueId") long leagueId)
        throws MissingResourceException {

        League league =  leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league [" + leagueId + "]"));

        return league.getTeamStatistics().entrySet().stream()
            .map(e -> new TeamDto(e.getKey(), e.getValue()))
            .collect(Collectors.toList());
    }

    public static class TeamDto {

        private final long id;
        private final String name;
        private final Collection<RosteredPlayer> roster;
        private final TeamStatistics statistics;


        public TeamDto(Team team, TeamStatistics statistics) {
            this.id = team.getId();
            this.name = team.getName();
            this.roster = team.getRoster();
            this.statistics = statistics;
        }

        public long getId() {
            return id;
        }

        public String getName() {
            return name;
        }

        public Collection<RosteredPlayer> getRoster() {
            return roster;
        }

        public TeamStatistics getStatistics() {
            return statistics;
        }
    }
}
