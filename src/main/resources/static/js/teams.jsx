
var TeamSidebar = React.createClass({

    compareTeams: function(a,b) {
        return a.name.localeCompare(b.name)
    },

    loadTeams: function () {
        $.ajax('/api/league/1/team').done(response => {

            this.setState({teams: response.sort(this.compareTeams)});
        });
    },

    getInitialState: function () {

        return ({teams: []});
    },
    componentDidMount: function () {
        this.loadTeams();
        setInterval(this.loadTeams, this.props.pollInterval);
    },
    render: function () {
        return (
            <div>
                <Teams teams={this.state.teams} />
                <Rosters teams={this.state.teams} />
            </div>
        )
    }
});

var Rosters = React.createClass({
    render: function() {

        var rosters = this.props.teams.map(team =>
            <Roster key={"roster." + team.id} team={team} />
        );

        return (
            <table className="table table-striped table-condensed">
                <thead>
                <tr>
                    <th>Roster</th>
                </tr>
                </thead>
                <tbody>
                {rosters}
                </tbody>
            </table>
        )
    }
});

var Teams = React.createClass({
    render: function() {
        var teams = this.props.teams.map(team =>
            <Team key={"team." + team.id} team={team} />
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
    render: function() {

        return (
            <tr id={"team." + this.props.team.id}>
                <td>{this.props.team.name}</td>
                <td>{this.props.team.statistics.availableBudget}</td>
                <td>{this.props.team.statistics.maxBid}</td>
                <td>{this.props.team.statistics.openRosterSpots}</td>
                <td>{this.props.team.statistics.adds}</td>
            </tr>
        )
    }
});

var Roster = React.createClass({

    render: function() {
        return (
            <tr id={"roster." + this.props.team.id}><td>Roster goes here for {this.props.team.name}</td></tr>
        )
    }
});

ReactDOM.render(
    <TeamSidebar pollInterval="2000" />,
    document.getElementById('teamSidebar')
  );

