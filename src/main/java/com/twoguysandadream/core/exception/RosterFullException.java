package com.twoguysandadream.core.exception;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by andrewk on 3/4/16.
 */
@ResponseStatus(code = HttpStatus.BAD_REQUEST)
public class RosterFullException extends BidException {

    public RosterFullException() {
        super("No roster space is available.");
    }
}
