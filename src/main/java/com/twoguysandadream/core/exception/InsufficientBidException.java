package com.twoguysandadream.core.exception;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(code = HttpStatus.BAD_REQUEST)
public class InsufficientBidException extends BidException {

    private static final NumberFormat NF = NumberFormat.getCurrencyInstance(Locale.US);

    public InsufficientBidException(BigDecimal bid, BigDecimal minBid) {

        super("Insufficient bid. Bid of " + NF.format(bid) + " does not meet minimum bid of " + NF.format(minBid));
    }
}
