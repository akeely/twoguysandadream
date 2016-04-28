
var TeamSidebar = React.createClass({

    compareTeams: function(a,b) {
        return a.name.localeCompare(b.name)
    },

    loadTeams: function () {

        var leagueId = $("meta[name='_league_id'").attr("content");

        $.ajax('/api/league/' + leagueId + '/team').done(response => {

            this.setState({teams: response.sort(this.compareTeams)});
        });
    },

    updateCurrentTeam: function(newTeam) {

        this.setState({currentTeam: newTeam});
    },

    getInitialState: function () {

        var activeTeam = $("meta[name='_team_id'").attr("content");

        return ({teams: [], currentTeam: activeTeam});
    },

    componentDidMount: function () {
        this.loadTeams();
        setInterval(this.loadTeams, this.props.pollInterval);
    },

    render: function () {
        return (
            <div>
                <Teams teams={this.state.teams} currentTeam={this.state.currentTeam} updateTeam={this.updateCurrentTeam} />
                <Rosters teams={this.state.teams} currentTeam={this.state.currentTeam} />
            </div>
        )
    }
});

var Teams = React.createClass({
    render: function() {
        var teams = this.props.teams.map(team =>
            <Team key={"team." + team.id} team={team} currentTeam={this.props.currentTeam} updateTeam={this.props.updateTeam}/>
        );

        return (
            <table className="table table-striped table-condensed">
                <thead>
                <tr>
                    <th>Team</th>
                    <th>Money</th>
                    <th>Max</th>
                    <th>Roster</th>
                    <th>Adds</th>
                </tr>
                </thead>
                <tbody>
                {teams}
                </tbody>
            </table>
        )
    }
});

var Team = React.createClass({

    updateTeam: function() {
        this.props.updateTeam(this.props.team.id);
    },

    render: function() {

        var highlightClass= '';
        if (this.props.team.id == this.props.currentTeam) {
            highlightClass = 'info';
        }

        return (
            <tr id={"team." + this.props.team.id} className={highlightClass}>
                <td><a href="#" onClick={this.updateTeam}>{this.props.team.name}</a></td>
                <td>{this.props.team.statistics.availableBudget}</td>
                <td>{this.props.team.statistics.maxBid}</td>
                <td>{this.props.team.statistics.openRosterSpots}</td>
                <td>{this.props.team.statistics.adds}</td>
            </tr>
        )
    }
});

var Rosters = React.createClass({
    render: function() {

        var teams = this.props.teams.filter(team => team.id == this.props.currentTeam)

        var rosters = teams.map(team =>
            <Roster key={"roster." + team.id} team={team} />
        );

        return (
            <div>
            {rosters}
            </div>
        )
    }
});

var Roster = React.createClass({

    render: function() {

        var playersWon = this.props.team.roster.map(entry =>
            <WonPlayer key={"won." + entry.player.id} rosterEntry={entry} />
        );

        return (
            <table className="table table-striped table-condensed">
                <thead>
                    <tr>
                        <th colSpan="3">{this.props.team.name}</th>
                    </tr>
                    <tr>
                        <th>Player</th>
                        <th>Cost</th>
                        <th>Pos</th>
                    </tr>
                </thead>
                <tbody>
                    {playersWon}
                </tbody>
            </table>
        )
    }
});

var WonPlayer = React.createClass({

    render: function() {

        var player = this.props.rosterEntry.player;
        var cost = this.props.rosterEntry.cost;

        var positions = player.positions
            .map(function(pos){return pos.name;})
            .join(', ');

        return (
            <tr>
                <td>{player.name}</td>
                <td>${cost}</td>
                <td>{positions}</td>
            </tr>
        )
    }

});

ReactDOM.render(
    <TeamSidebar pollInterval="2000" />,
    document.getElementById('teamSidebar')
  );

