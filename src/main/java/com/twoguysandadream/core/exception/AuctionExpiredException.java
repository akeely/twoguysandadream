package com.twoguysandadream.core.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(code = HttpStatus.GONE)
public class AuctionExpiredException extends BidException {

    public AuctionExpiredException(long playerId) {
        super("Bid failed for player " + playerId + ". The auction has expired.");
    }
}
