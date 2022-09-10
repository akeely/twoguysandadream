package com.twoguysandadream.security;

import java.util.Optional;
import java.util.OptionalLong;

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

    /**
     * Find the user associated with the given token, or create a new user if one doesn't exist.
     *
     * @param openIdToken The openId token.
     * @return The user.
     */
    Optional<AuctionUser> findOne(String openIdToken);

    /**
     * Find the user associated with the given email address.
     *
     * @param email The email address
     * @return The user.
     */
    Optional<AuctionUser> findByEmail(String email);

    /**
     * Find the team associated with the current user in the given league.
     *
     * @param userId The user to find the team for.
     * @param leagueId The league that the team is in.
     * @return The identifier of the team.
     */
    OptionalLong findTeamId(long userId, long leagueId);

    /**
     * Find the name of the owner for the given ID.
     * @param userId
     * @return
     */
    Optional<String> findOwner(long userId);
}
