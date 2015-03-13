package com.twoguysandadream.resources;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.ResponseStatus;

/**
 * Created by andrewk on 3/13/15.
 */
@ResponseStatus(value = HttpStatus.NOT_FOUND)
public class MissingResourceException extends Exception {

    public MissingResourceException(String resourceDescription) {
        super(buildMessage(resourceDescription));
    }

    public MissingResourceException(String resourceDescription, Exception cause) {

        super(buildMessage(resourceDescription), cause);
    }

    private static String buildMessage(String resourceDescription) {

        return "No resource exists: " + resourceDescription;
    }
}
