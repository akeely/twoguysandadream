var App = React.createClass({
    getInitialState: function () {
        return ({auctionPlayers: []});
    },
    componentDidMount: function () {
        $.ajax('/api/league/1/bid').done(response => {
            this.setState({auctionPlayers: response});
        });
    },
    render: function () {
        return (
            <AuctionBoard auctionPlayers={this.state.auctionPlayers}/>
        )
    }
});

var AuctionBoard = React.createClass({
    render: function () {
        var bids = this.props.auctionPlayers.map(bid =>
            <Bid key={bid.player.id} bid={bid}/>
        );
        return (
            <table>
                <tr>
                    <th>Player</th>
                    <th>Leading Bidder</th>
                    <th>Bid</th>
                </tr>
                {bids}
            </table>
        )
    }
})

var Bid = React.createClass({
    render: function () {
        return (
            <tr>
                <td>{this.props.bid.player.name}</td>
                <td>{this.props.bid.team}</td>
                <td>{this.props.bid.amount}</td>
            </tr>
        )
    }
});

setInterval(function() {
  ReactDOM.render(
    <App />,
    document.getElementById('example')
  );
}, 500);
