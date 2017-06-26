package com.twoguysandadream.resources;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import com.twoguysandadream.core.League;
import com.twoguysandadream.core.LeagueRepository;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamRepository;
import com.twoguysandadream.security.AuctionUser;

@RestController
@RequestMapping(ApiConfiguration.ROOT_PATH + "/league")
public class LeagueResource {

    private final LeagueRepository leagueRepository;
    private final TeamRepository teamRepository;

    @Autowired
    public LeagueResource(LeagueRepository leagueRepository, TeamRepository teamRepository) {
        this.leagueRepository = leagueRepository;
        this.teamRepository = teamRepository;
    }

    @GetMapping(path = "/{leagueId}")
    public League findOne(@PathVariable long leagueId) throws MissingResourceException {
        return leagueRepository.findOne(leagueId)
                .orElseThrow(() -> new MissingResourceException("league: " + leagueId));
    }

    @PutMapping(path = "/{leagueId}/draftstatus")
    public void updateDraftStatus(@PathVariable long leagueId, @RequestBody DraftStatusDto draftStatus,
            @AuthenticationPrincipal AuctionUser user) throws MissingResourceException {

        user.getId()
                .flatMap(id -> teamRepository.findByOwner(leagueId, id))
                .filter(Team::isCommissioner)
                .orElseThrow(() -> new AuthorizationException("Must be commissioner to update draft status."));

        leagueRepository.updateDraftStatus(leagueId, League.DraftStatus.fromDescription(draftStatus.getStatus()));
    }

    private static class DraftStatusDto {

        private String status;

        public String getStatus() {
            return status;
        }

        public void setStatus(String status) {
            this.status = status;
        }
    }
}
