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
                existing[i].secondsRemaining = EXPIRED;
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
            <Bid key={"bid." + bid.player.id} bid={bid} />
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

    minBid: function() {
        if (this.props.bid.amount < 10) {
            return this.props.bid.amount + 0.5;
        }

        return this.props.bid.amount + 1;
    },

    stepAmount: function() {

        if (this.props.bid.amount < 10) {
            return 0.5;
        }

        return 1;
    },

    bidId: function() {
        return this.props.bid.player.id + ".bid.amount";
    },

    bid: function() {
        alert("Bidding on " + this.props.bid.player.name + " for $" + document.getElementById(this.bidId()).value);

        $.ajax({
            'url': '/api/league/1/bid/' + this.props.bid.player.id,
            'data': JSON.stringify({ amount: document.getElementById(this.bidId()).value }),
            'type': 'POST',
            'processData': false,
            'contentType': 'application/json'
        });
    },

    render: function() {

        return (
            <div className="input-group input-group-sm">
                <input type="number" className="form-control" aria-label="Bid" id={this.bidId()} min={this.minBid()} step={this.stepAmount()} />
                <div className="input-group-btn">
                    <button type="button" className="btn btn-default" aria-label="Bid" onClick={this.bid}>Bid</button>
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
        if(this.props.bid.secondsRemaining === EXPIRED) {
            return (<RemoveBid bid={this.props.bid} />);
        }
        else {
            return (<BidEntry bid={this.props.bid} />);
        }
    }
});

var Bid = React.createClass({

    toTimeString: function(time) {
        var minutes = Math.floor(time / 60);
        var seconds = time - (minutes * 60);

        if (seconds < 10) {seconds = "0"+seconds;}
        return minutes + ':' + seconds;
    },

    render: function () {

        var timeString = this.props.bid.secondsRemaining;
        if (timeString !== EXPIRED) {
            var timeString = this.toTimeString(this.props.bid.secondsRemaining);
        }

        return (
            <tr id={"bid." + this.props.bid.player.id} className={this.props.bid.secondsRemaining === EXPIRED ? 'danger' : ''}>
                <td>{this.props.bid.player.name}</td>
                <td>{this.props.bid.player.positions
                        .map(function(pos){return pos.name;})
                        .join(', ')}
                </td>
                <td>{this.props.bid.amount}</td>
                <td>{this.props.bid.team}</td>
                <td className={this.props.bid.secondsRemaining < 21 ? 'warning' : ''}>{timeString}</td>
                <td width="110" className="text-center">
                    <BidColumn bid={this.props.bid} />
                </td>
            </tr>
        )
    }
});

ReactDOM.render(
    <App pollInterval="500" />,
    document.getElementById('auctionBoard')
  );

