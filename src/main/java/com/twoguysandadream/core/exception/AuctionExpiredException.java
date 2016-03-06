package com.twoguysandadream.core.exception;

public class AuctionExpiredException extends BidException {

    public AuctionExpiredException(long playerId) {
        super("Bid failed for player " + playerId + ". The auction has expired.");
    }
}
