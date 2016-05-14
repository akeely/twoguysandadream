package com.twoguysandadream.security;

public class NotRegisteredException extends RuntimeException {

    private final String openIdToken;

    public NotRegisteredException(String openIdToken) {
        super("No user registered with token " + openIdToken);
        this.openIdToken = openIdToken;
    }

    public String getToken() {
        return openIdToken;
    }
}
