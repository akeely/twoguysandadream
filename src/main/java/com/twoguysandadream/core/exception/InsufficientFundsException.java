package com.twoguysandadream.core.exception;

import java.math.BigDecimal;
import java.text.NumberFormat;
import java.util.Locale;

public class InsufficientFundsException extends BidException {

    private static final NumberFormat NF = NumberFormat.getCurrencyInstance(Locale.US);

    public InsufficientFundsException(BigDecimal amount, BigDecimal maxBid) {
        super("Bid of " + NF.format(amount) + " exceeds maximum available bid of " + NF.format(maxBid));
    }
}
