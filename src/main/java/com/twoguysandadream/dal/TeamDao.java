package com.twoguysandadream.dal;

import com.google.common.collect.ImmutableMap;
import com.twoguysandadream.core.Player;
import com.twoguysandadream.core.Position;
import com.twoguysandadream.core.RosteredPlayer;
import com.twoguysandadream.core.Team;
import com.twoguysandadream.core.TeamRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.core.namedparam.SqlParameterSource;
import org.springframework.stereotype.Repository;

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Repository
public class TeamDao implements TeamRepository {

    @Value("${team.findAll}")
    private String findAllQuery;
    @Value("${team.findOne}")
    private String findOneQuery;
    @Value("${team.save}")
    private String saveQuery;
    @Value("${team.findRosters}")
    private String findRostersQuery;

    private final NamedParameterJdbcTemplate jdbcTemplate;

    @Autowired
    public TeamDao(NamedParameterJdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override public List<Team> findAll(long leagueId) {
        Map<Long,List<RosteredPlayer>> rosters = getRosters(leagueId);

        return jdbcTemplate.query(findAllQuery, Collections.singletonMap("leagueId", leagueId),
            new TeamRowMapper(rosters));
    }

    @Override public Optional<Team> findOne(long leagueId, long teamId) {

        Map<Long,List<RosteredPlayer>> rosters = getRosters(leagueId);

        Map<String, Long> params = ImmutableMap.<String, Long>builder()
            .put("leagueId", leagueId)
            .put("teamId", teamId)
            .build();

        try {
            return Optional.of(jdbcTemplate.queryForObject(findOneQuery, params, new TeamRowMapper(rosters)));
        } catch (EmptyResultDataAccessException e) {
            return Optional.empty();
        }
    }

    @Override public void update(long leagueId, Team team) {

        jdbcTemplate.update(saveQuery, buildParams(leagueId, team));
    }

    private SqlParameterSource buildParams(long leagueId, Team team) {

        Map<String, Object> params = ImmutableMap.<String, Object>builder()
            .put("leagueId", leagueId)
            .put("teamId", team.getId())
            .put("adds", team.getAdds())
            .put("name", team.getName())
            .put("budgetAdjustment", team.getBudgetAdjustment())
            .build();

        return new MapSqlParameterSource(params);
    }

    private Map<Long,List<RosteredPlayer>> getRosters(long leagueId) {

        RosteredPlayerCallbackHandler handler = new RosteredPlayerCallbackHandler();
        jdbcTemplate.query(findRostersQuery, Collections.singletonMap("leagueId", leagueId),
            handler);

        return handler.getRosters();
    }

    private String decodeString(String string) {

        try {
            return new String(string.getBytes("ISO-8859-1"), "UTF-8");
        }
        catch (UnsupportedEncodingException e) {

            return string;
        }
    }

    public class TeamRowMapper implements RowMapper<Team> {

        private final Map<Long,List<RosteredPlayer>> rosters;

        public TeamRowMapper(Map<Long, List<RosteredPlayer>> rosters) {
            this.rosters = rosters;
        }

        @Override public Team mapRow(ResultSet rs, int rowNum) throws SQLException {

            long id = rs.getLong("id");
            String name = rs.getString("name");
            Collection<RosteredPlayer> roster = rosters.getOrDefault(id, Collections.emptyList());
            BigDecimal budgetAdjustment = rs.getBigDecimal("money_plusminus");
            int adds = rs.getInt("num_adds");
            return new Team(id,name,roster,budgetAdjustment,adds);
        }
    }

    public class RosteredPlayerCallbackHandler implements RowCallbackHandler {

        private final Map<Long,List<RosteredPlayer>> rosters = new HashMap<>();

        @Override public void processRow(ResultSet rs) throws SQLException {

            long team = rs.getLong("teamId");

            long id = rs.getLong("playerid");
            String name = decodeString(rs.getString("name"));
            Collection<Position> positions = Collections.singletonList(
                new Position(rs.getString("position")));
            String realTeam = rs.getString("realTeam");
            int rank = rs.getInt("rank");

            Player player = new Player(id, name, positions, realTeam, rank);

            BigDecimal cost = rs.getBigDecimal("price");

            RosteredPlayer rosteredPlayer = new RosteredPlayer(player, cost);
            rosters.putIfAbsent(team, new ArrayList<>());
            rosters.get(team).add(rosteredPlayer);
        }

        public Map<Long, List<RosteredPlayer>> getRosters() {
            return rosters;
        }
    }
}
