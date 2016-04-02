
var TeamSidebar = React.createClass({

    loadTeams: function () {
        $.ajax('/api/league/1/team').done(response => {

            this.setState({teams: response});
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
            <Teams teams={this.state.teams} />
        )
    }
});

var Teams = React.createClass({
    render: function() {
        var teams = this.props.teams.map(team =>
            <Team key={"team." + team.id} team={team} />
        );

        var rosters = this.props.teams.map(team =>
            <Roster key={"roster." + team.id} roster={team.roster} />
        );
        return (
            <div>
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

                {rosters}
            </div>
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
            <p>Roster goes here</p>
        )
    }
});

ReactDOM.render(
    <TeamSidebar pollInterval="2000" />,
    document.getElementById('teamSidebar')
  );

