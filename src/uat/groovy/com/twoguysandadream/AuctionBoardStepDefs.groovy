package com.twoguysandadream

import cucumber.api.DataTable
import cucumber.api.PendingException

/**
 * Created by andrewk on 2/22/15.
 */

this.metaClass.mixin(cucumber.api.groovy.Hooks)
this.metaClass.mixin(cucumber.api.groovy.EN)

Given(~'^a league called (.*) exists$') { league ->

}

Given(~/^The following teams are in (.*):$/) { String league, DataTable teams ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^(.*) has a salary cap of \$(\d+)$/) { String league, int salaryCap ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^(.*) has (\d+) roster spots per team$/) { String league, int rosterSpots ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^The application is running$/) { ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

When(~/^I retrieve the current auction board for (.*)$/) { String league ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^(\d+) empty rosters exist$/) { int count ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^(\d+) team statistics exist$/) { int count ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^All teams have \$(\d+)$/) { int remainingMoney ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^All teams have (\d+) roster spots available$/) { int availableRosterSpots ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^All teams have a maximum bid of \$(\d+\.?\d*)$/) { String maxBid ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^the following bids are open in League A:$/) { DataTable bids ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^the auction board contains the following bids:$/) { DataTable bids ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^the following players have been won in (.*):$/) { String league, DataTable wonPlayers ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^the roster for (.*) has (.*)$/) { String team, String player ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^(.*) has (\d+) roster spots available$/) { String team, int rosterSpots ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}


Then(~/^(.*) has \$(\d+\.?\d*)$/) { String team, String money ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}


Then(~/^(.*) has a maximum bid of \$(\d+\.?\d*)$/) { String team, String maxBid ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Given(~/^every team has (\d+) adds$/) { int arg1 ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^the following rosters are returned:$/) { DataTable rosters ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}

Then(~/^the following team statistics are returned:$/) { DataTable statistics ->
    // Write code here that turns the phrase above into concrete actions
    //throw new PendingException()
}
