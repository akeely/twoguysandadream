package com.twoguysandadream.core.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by andrewk on 2/27/16.
 */
@ResponseStatus(code = HttpStatus.BAD_REQUEST)
public class InvalidBidException extends BidException {

    public InvalidBidException(String message) {
        super(message);
    }
}
