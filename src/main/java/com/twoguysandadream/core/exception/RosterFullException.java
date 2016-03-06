package com.twoguysandadream.core.exception;

/**
 * Created by andrewk on 3/4/16.
 */
public class RosterFullException extends BidException {

    public RosterFullException() {
        super("No roster space is available.");
    }
}
