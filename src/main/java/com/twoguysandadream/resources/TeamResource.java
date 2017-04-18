package com.twoguysandadream.resources;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.RosteredPlayer;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamRepository;
import com.twoguysandadream.core.TeamStatistics;
import com.twoguysandadream.security.AuctionUser;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league/{leagueId}/team")
public class TeamResource {

    private final LeagueRepository leagueRepository;
    private final TeamRepository teamRepository;

    @Autowired
    public TeamResource(LeagueRepository leagueRepository, TeamRepository teamRepository) {
        this.leagueRepository = leagueRepository;
        this.teamRepository = teamRepository;
    }

    @GetMapping
    public List<TeamDto> findAll(@PathVariable("leagueId") long leagueId)
        throws MissingResourceException {

        League league =  leagueRepository.findOne(leagueId)
            .orElseThrow(() -> new MissingResourceException("league [" + leagueId + "]"));

        return league.getTeams().stream()
            .map(t -> new TeamDto(t, league.getTeamStatistics().get(t.getId())))
            .collect(Collectors.toList());
    }

    @GetMapping("/me")
    public Optional<TeamDto> findActive(@PathVariable("leagueId") long leagueId,
            @AuthenticationPrincipal AuctionUser user) {

        return user.getId()
                .flatMap(id -> teamRepository.findByOwner(leagueId, id))
                .map(t -> new TeamDto(t, new TeamStatistics(null, null, 0, t.getAdds())));
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
