package com.twoguysandadream.security;

/**
 * Created by andrewk on 11/1/15.
 */
public interface AuctionUserRepository {

    /**
     * Find the user associated with the given token, or create a new user if one doesn't exist.
     *
     * @param openIdToken The openId token.
     * @return The user.
     */
    AuctionUser findOrCreate(String openIdToken);
}
