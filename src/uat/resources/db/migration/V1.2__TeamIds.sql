-- Replace owner with ownerid in teams table
ALTER TABLE `teams` ADD `ownerid` INT NULL;
UPDATE teams AS t
  INNER JOIN passwd AS p
  ON p.name=t.owner
SET t.ownerid=p.id;
ALTER TABLE `teams` MODIFY `ownerid` INT NOT NULL;
ALTER TABLE `teams` DROP PRIMARY KEY;
ALTER TABLE `teams` DROP `owner`;

-- Add new ID column as primary key to teams table
ALTER TABLE `teams` ADD `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Update auction_players to use teamid
ALTER TABLE `auction_players` ADD `teamid` INT NULL;
UPDATE auction_players AS a
  INNER JOIN teams AS t
  ON a.team=t.name
SET a.teamid=t.id;
ALTER TABLE `auction_players` DROP `team`;

-- Update final_rosters to use teamid
ALTER TABLE `final_rosters` ADD `teamid` INT NULL;
UPDATE final_rosters AS a
  INNER JOIN teams AS t
  ON a.team=t.name
SET a.teamid=t.id;
ALTER TABLE `final_rosters` DROP `team`;

-- Update players_won to use teamid
ALTER TABLE `players_won` ADD `teamid` INT NULL;
UPDATE players_won AS a
  INNER JOIN teams AS t
  ON a.team=t.name
SET a.teamid=t.id;
ALTER TABLE `players_won` DROP `team`;


