var App = React.createClass({
    loadAuctionBoard: function () {
        $.ajax('/api/league/1/bid').done(response => {
         this.setState({auctionPlayers: response});
        });
    },

    getInitialState: function () {
        return ({auctionPlayers: []});
    },
    componentDidMount: function () {
        this.loadAuctionBoard();
        // TODO: setInterval(this.loadAuctionBoard, this.props.pollInterval);
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
            <table className="table table-striped table-condensed">
                <thead>
                <tr>
                    <th>Player</th>
                    <th>Position</th>
                    <th>Current Bid</th>
                    <th>Bidder</th>
                    <th>Time Remaining</th>
                    <th>Bid</th>
                </tr>
                </thead>
                <tbody>
                {bids}
                </tbody>
            </table>
        )
    }
})

var Bid = React.createClass({
    render: function () {
        return (
            <tr id="bid.{this.props.bid.player.id}">
                <td>{this.props.bid.player.name}</td>
                <td>{this.props.bid.player.positions
                        .map(function(pos){return pos.name;})
                        .join(', ')}
                </td>
                <td>{this.props.bid.amount}</td>
                <td>{this.props.bid.team}</td>
                <td>{this.props.bid.expirationTime}</td>
                <td width="110">
                    <div className="input-group input-group-sm">
                        <input type="text" className="form-control" aria-label="Bid" />
                        <div className="input-group-btn">
                            <button type="button" className="btn btn-default" aria-label="Bid">Bid</button>
                        </div>
                    </div>
                </td>
            </tr>
        )
    }
});

ReactDOM.render(
    <App pollInterval="2000" />,
    document.getElementById('example')
  );

