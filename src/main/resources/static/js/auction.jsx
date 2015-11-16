var EXPIRED = 'EXPIRED';

var App = React.createClass({

    getMatchingBid: function(playerId, bids) {

        for (var i = 0; i < bids.length; i++) {
            if (bids[i].player.id === playerId) {
                return bids[i];
            }
        }

        return null;
    },

    mergePlayers: function(existing, updated) {

        var mergedBids = [];
        for (var i = 0; i < existing.length; i++) {
            var updatedBid = this.getMatchingBid(existing[i].player.id, updated);
            if (updatedBid === null) {
                existing[i].expirationTime = EXPIRED;
                existing[i].removeFunction = this.removePlayer.bind(this, existing[i].player.id);
                mergedBids.push(existing[i]);
            }
            else {
                mergedBids.push(updatedBid);
            }
        }

        for (var i = 0; i < updated.length; i++) {
            var existingBid = this.getMatchingBid(updated[i].player.id, existing);
            if (existingBid === null) {
                mergedBids.push(updated[i]);
            }
        }

        return mergedBids;
    },

    filterOutPlayer: function(playerId, bid) {
        return playerId != bid.player.id;
    },

    removePlayer: function(id) {

        var filterId = this.filterOutPlayer.bind(this, id);
        var updatedState = this.state.auctionPlayers.filter(filterId);

        this.setState({auctionPlayers: updatedState});
    },

    loadAuctionBoard: function () {
        $.ajax('/api/league/1/bid').done(response => {

            var merged = this.mergePlayers(this.state.auctionPlayers, response);
            this.setState({auctionPlayers: merged});
        });
    },

    getInitialState: function () {

        return ({auctionPlayers: []});
    },
    componentDidMount: function () {
        this.loadAuctionBoard();
        setInterval(this.loadAuctionBoard, this.props.pollInterval);
    },
    render: function () {
        return (
            <AuctionBoard auctionPlayers={this.state.auctionPlayers} />
        )
    }
});

var AuctionBoard = React.createClass({
    render: function () {
        var bids = this.props.auctionPlayers.map(bid =>
            <Bid key={bid.player.id} bid={bid} />
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
});

var BidEntry = React.createClass({
    render: function() {
        return (
            <div className="input-group input-group-sm">
                <input type="text" className="form-control" aria-label="Bid" />
                <div className="input-group-btn">
                    <button type="button" className="btn btn-default" aria-label="Bid">Bid</button>
                </div>
            </div>
        );
    }
});

var RemoveBid = React.createClass({
    render: function() {
        return (
            <a href="#" onClick={this.props.bid.removeFunction}>
                <i className="fa fa-times-circle fa-lg" />
            </a>
        );
    }
});

var BidColumn = React.createClass({
    render: function() {
        var column;
        if(this.props.bid.expirationTime === EXPIRED) {
            return (<RemoveBid bid={this.props.bid} />);
        }
        else {
            return (<BidEntry />);
        }
    }
});

var Bid = React.createClass({
    render: function () {


        return (
            <tr id={"bid." + this.props.bid.player.id}>
                <td>{this.props.bid.player.name}</td>
                <td>{this.props.bid.player.positions
                        .map(function(pos){return pos.name;})
                        .join(', ')}
                </td>
                <td>{this.props.bid.amount}</td>
                <td>{this.props.bid.team}</td>
                <td>{this.props.bid.expirationTime}</td>
                <td width="110" className="text-center">
                    <BidColumn bid={this.props.bid} />
                </td>
            </tr>
        )
    }
});

ReactDOM.render(
    <App pollInterval="2000" />,
    document.getElementById('example')
  );

