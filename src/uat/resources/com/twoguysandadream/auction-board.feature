Feature: Retrieve the current auction board

Background: Set up the test league
  Given a league called Test League exists
  And  The following teams are in Test League:
    | Team   |
    | Team A |
    | Team B |
    | Team C |
  And Test League has a salary cap of $200
  And Test League has 12 roster spots per team

Scenario: Retrieve an empty auction board from league with teams
  When I retrieve the current auction board for Test League
  Then 3 team statistics exist
  And All teams have $200
  And All teams have 12 roster spots available
  And All teams have a maximum bid of $194.50

Scenario: A single player is available for auction
  Given the following bids are open in League A:
    | Team   | Player    | Amount |
    | Team A | Player A  | $5.50  |
  When I retrieve the current auction board for Test League
  Then the auction board contains the following bids:
    | Team   | Player    | Amount |
    | Team A | Player A  | $5.50  |
  And Team A has a maximum bid of $194.50
  And All teams have $200
  And All teams have 12 roster spots available

Scenario: A single player has been won
  Given the following players have been won in Test League:
    | Team   | Player    | Amount |
    | Team A | Player A  | $5.50  |
  When I retrieve the current auction board for Test League
  Then the roster for Team A has Player A
  And  Team A has 11 roster spots available
  And  Team B has 12 roster spots available
  And  Team A has $194.50
  And  Team B has $200
  And  Team A has a maximum bid of $189.50
  And  Team B has a maximum bid of $194.50

Scenario: Putting everything together
  Given the following players have been won in Test League:
    | Team   | Player    | Amount |
    | Team A | Player A  | $5.50  |
    | Team A | Player B  | $4     |
    | Team B | Player C  | $2     |
    | Team C | Player D  | $15.50 |
    | Team C | Player E  | $1     |
    | Team C | Player F  | $100   |
  And the following bids are open in Test League:
    | Team   | Player    | Amount |
    | Team A | Player G  | $5.50  |
    | Team A | Player H  | $1     |
    | Team B | Player I  | $25    |
    | Team C | Player J  | $14.50 |
  And every team has 2 adds
  When I retrieve the current auction board for Test League
  Then the following rosters are returned:
    | Team   | Player    | Amount |
    | Team A | Player A  | $5.5   |
    | Team A | Player B  | $4     |
    | Team B | Player C  | $2     |
    | Team C | Player D  | $15.5  |
    | Team C | Player E  | $1     |
    | Team C | Player F  | $100   |
  And the auction board contains the following bids:
    | Team   | Player    | Amount |
    | Team A | Player G  | $5.50  |
    | Team A | Player H  | $1     |
    | Team B | Player I  | $25    |
    | Team C | Player J  | $14.50 |
  And the following team statistics are returned:
    | Team   | Max Bid | Money   | Roster Spots | Adds |
    | Team A | $186    | $190.5  | 10           | 2    |
    | Team B | $193    | $198    | 11           | 2    |
    | Team C | $79.5   | $83.5   | 9            | 2    |
