package com.twoguysandadream.core.exception;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

@ResponseStatus(code = HttpStatus.BAD_REQUEST)
public class InsufficientFundsException extends BidException {

    private static final NumberFormat NF = NumberFormat.getCurrencyInstance(Locale.US);

    public InsufficientFundsException(BigDecimal amount, BigDecimal maxBid) {
        super("Bid of " + NF.format(amount) + " exceeds maximum available bid of " + NF.format(maxBid));
    }
}
