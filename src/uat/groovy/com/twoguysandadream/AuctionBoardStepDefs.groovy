package com.twoguysandadream

import cucumber.api.DataTable
import cucumber.api.PendingException
import groovy.transform.Field
import groovyx.net.http.ContentType
import groovyx.net.http.HTTPBuilder
import groovyx.net.http.Method
import org.apache.commons.dbcp2.BasicDataSource
import org.apache.http.util.EntityUtils
import org.flywaydb.core.Flyway
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import static groovyx.net.http.ContentType.*
import javax.sql.DataSource

/**
 * Created by andrewk on 2/22/15.
 */

this.metaClass.mixin(cucumber.api.groovy.Hooks)
this.metaClass.mixin(cucumber.api.groovy.EN)


@Field
NamedParameterJdbcTemplate jdbcTemplate
@Field
def requestResponse

Before() {

    Flyway flyway = new Flyway()

    flyway.setDataSource("jdbc:mysql://192.168.33.10:3306/auction", "uat", "password")
    flyway.setLocations("filesystem:src/uat/resources/db/migration")
    flyway.clean()
    flyway.migrate()

    BasicDataSource dataSource = new BasicDataSource()
    dataSource.setDriverClassName("com.mysql.jdbc.Driver")
    dataSource.setUrl("jdbc:mysql://192.168.33.10:3306/auction")
    dataSource.setUsername("uat")
    dataSource.setPassword("password")
    jdbcTemplate = new NamedParameterJdbcTemplate(dataSource)
}

Given(~'^a league called (.*) exists$') { league ->

    def params = ["league" : (league)]
    jdbcTemplate.update("""
INSERT INTO leagues
  (name, password, owner, max_teams, salary_cap, auction_length, bid_time_ext, bid_time_buff)
VALUES
  (:league, 'pwd', 'owner', 12, 200, 180, 120, 120)

    """, params)

}

Given(~/^The following teams are in (.*):$/) { String league, DataTable teams ->

    def teamNames = teams.asList(String.class).tail()
    teamNames.each { teamName ->
        def params = ["league" : (league), "team" : (teamName)]
        jdbcTemplate.update("INSERT INTO teams (owner, name, league) VALUES (:team, :team, :league)", params)
    }
}

Given(~/^(.*) has a salary cap of \$(\d+)$/) { String league, int salaryCap ->

    def params = ["league" : (league), "cap" : salaryCap]
    jdbcTemplate.update("UPDATE leagues SET salary_cap = :cap WHERE name = :league", params)
}

Given(~/^(.*) has (\d+) roster spots per team$/) { String league, int rosterSpots ->

    (9..rosterSpots).eachWithIndex { i, idx ->
        def params = ["league": (league), "position" : "BN$idx"]

        jdbcTemplate.update("INSERT INTO positions (league, position) VALUES (:league, :position)", params)
    }
}

When(~/^I retrieve the current auction board for (.*)$/) { String league ->

    HTTPBuilder http = new HTTPBuilder("http://192.168.33.10")

    http.request(Method.POST, JSON) {
        uri.path = "/cgi-bin/fantasy/checkBids.pl"
        body = [ league : league ]
        requestContentType = ContentType.URLENC

        response.success = { resp, json ->
            requestResponse = json
        }
    }

    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^(\d+) empty rosters exist$/) { int count ->

    assert requestResponse.ROSTERS?.size() == 3

}

Then(~/^(\d+) team statistics exist$/) { int count ->

    assert requestResponse.TEAMS.size() == 3
}

Then(~/^All teams have \$(\d+)$/) { int remainingMoney ->

    requestResponse.TEAMS.each { Map.Entry team ->
        assert team.value.MONEY == remainingMoney
    }
}

Then(~/^All teams have (\d+) roster spots available$/) { int availableRosterSpots ->

    requestResponse.TEAMS.each { Map.Entry team ->
        assert team.value.SPOTS == availableRosterSpots
    }
}

Then(~/^All teams have a maximum bid of \$(\d+\.?\d*)$/) { BigDecimal maxBid ->

    requestResponse.TEAMS.each { Map.Entry team ->
        assert team.value.MAX_BID == maxBid
    }
}

Given(~/^the following bids are open in (.*):$/) { String league, DataTable bids ->

    bids.raw().tail().each { bid ->

        def params = [league: league, team: bid.get(0), name: bid.get(1), bid: (bid.get(2) - '$'),
                      time: (System.currentTimeMillis()/1000 + 180)]
        jdbcTemplate.update("INSERT INTO players (name, active, yahooid, position) VALUES (:name,1,1,'OF')",
                params)
        jdbcTemplate.update("""
INSERT INTO auction_players (name, price, team, time, league)
SELECT playerid, :bid, :team, :time, :league
FROM players
WHERE name=:name
""", params)
    }
}

Then(~/^the auction board contains the following bids:$/) { DataTable bids ->

    def board = [bids.raw().head()]
    requestResponse.PLAYERS?.each { id, player ->
        board.add([player.BIDDER, player.NAME, "\$${player.BID}"])
    }

    assert bids.raw() == board
}

Given(~/^the following players have been won in (.*):$/) { String league, DataTable wonPlayers ->

    wonPlayers.raw().tail().each { bid ->

        def params = [league: league, team: bid.get(0), name: bid.get(1), bid: (bid.get(2) - '$'),
                      time: (System.currentTimeMillis()/1000 - 180)]
        jdbcTemplate.update("INSERT INTO players (name, active, yahooid, position) VALUES (:name,1,1, 'OF')",
                params)
        jdbcTemplate.update("""
INSERT INTO players_won (name, price, team, time, league)
SELECT playerid, :bid, :team, :time, :league
FROM players
WHERE name=:name
""", params)
    }
}

Then(~/^the roster for (.*) has (.*)$/) { String team, String player ->

    assert requestResponse.ROSTERS?.get(team)?.find { it.NAME == player }
}

Then(~/^(.*) has (\d+) roster spots available$/) { String team, int rosterSpots ->

    assert requestResponse.TEAMS.get(team).SPOTS == rosterSpots
}


Then(~/^(.*) has \$(\d+\.?\d*)$/) { String team, BigDecimal money ->

    assert requestResponse.TEAMS.get(team).MONEY == money
}


Then(~/^(.*) has a maximum bid of \$(\d+\.?\d*)$/) { String team, BigDecimal maxBid ->

    assert requestResponse.TEAMS.get(team).MAX_BID == maxBid
}

Given(~/^every team has (\d+) adds$/) { int adds ->

    def params = [ adds: (adds) ]
    jdbcTemplate.update("UPDATE teams SET num_adds=:adds", params)
}

Then(~/^the following rosters are returned:$/) { DataTable rosters ->

    List<List<String>> response = [rosters.raw().head()]
    requestResponse.ROSTERS?.each { team, players ->
        players.each { player ->
            response.add([team, player.NAME, "\$${player.PRICE}"])

        }
    }

    assert rosters.raw() == response
}

Then(~/^the following team statistics are returned:$/) { DataTable statistics ->

    def response = [statistics.raw().head()]
    requestResponse.TEAMS?.each { team, stats ->

            response.add([(team), "\$${stats.MAX_BID}", "\$${stats.MONEY}", stats.SPOTS, stats.ADDS])

    }

    assert statistics.raw() == response
}
