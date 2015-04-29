Feature: As a user, I need to log in

Background:
  Given a user named test exists
  And the password for test is pass

Scenario: Authenticate an existing user
  When a user logs in with test:pass
  Then the user is authenticated

Scenario: Fail to authenticate with the wrong password
  When a user logs in with test:wrong
  Then the user is not authenticated

Scenario: An authenticated user identity is correct
  Given the user test is logged in
  When the user accesses the user profile page
  Then the user test is returned

