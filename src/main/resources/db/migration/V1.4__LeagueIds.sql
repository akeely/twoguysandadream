-- Update leagues to use ownerid
ALTER TABLE leagues ADD ownerid INT NULL;
UPDATE leagues AS l
  INNER JOIN passwd AS p
  ON p.name=l.owner COLLATE latin1_general_cs
SET l.ownerid=p.id;
ALTER TABLE `leagues` MODIFY `ownerid` INT NOT NULL;
ALTER TABLE `leagues` DROP `owner`;

-- Add leagueID primary key
ALTER TABLE `leagues` DROP PRIMARY KEY;
ALTER TABLE `leagues` ADD `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Update teams to use leagueID
ALTER TABLE `teams` ADD `leagueid` INT NULL;
UPDATE teams AS t
  INNER JOIN leagues AS l
  ON t.league=l.name
SET t.leagueid=l.id;
ALTER TABLE `teams` DROP `league`;
ALTER TABLE `teams` MODIFY `leagueid` INT NOT NULL;

-- Update auction_players to use leagueID
ALTER TABLE `auction_players` ADD `leagueid` INT NULL;
UPDATE auction_players AS p
  INNER JOIN leagues AS l
  ON p.league=l.name
SET p.leagueid=l.id;
ALTER TABLE `auction_players` DROP `league`;
ALTER TABLE `auction_players` MODIFY `leagueid` INT NOT NULL;

-- Update players_won to use leagueID
ALTER TABLE `players_won` ADD `leagueid` INT NULL;
UPDATE players_won AS p
  INNER JOIN leagues AS l
  ON p.league=l.name
SET p.leagueid=l.id;
-- Remove corrupt data
DELETE FROM `players_won` WHERE `leagueid` IS NULL;
ALTER TABLE `players_won` DROP PRIMARY KEY, ADD PRIMARY KEY (`leagueid`, `playerid`);
ALTER TABLE `players_won` DROP `league`;
ALTER TABLE `players_won` MODIFY `leagueid` INT NOT NULL;

-- Update positions to use leagueID
ALTER TABLE `positions` ADD `leagueid` INT NULL;
UPDATE positions AS p
  INNER JOIN leagues AS l
  ON p.league=l.name COLLATE latin1_general_cs
SET p.leagueid=l.id;
-- Remove corrupt data
DELETE FROM `positions` WHERE `leagueid` IS NULL;
ALTER TABLE `positions` DROP PRIMARY KEY, ADD PRIMARY KEY (`leagueid`, `position`);
ALTER TABLE `positions` DROP `league`;
ALTER TABLE `positions` MODIFY `leagueid` INT NOT NULL;
