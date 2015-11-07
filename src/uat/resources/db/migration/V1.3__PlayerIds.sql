-- Update existing column names that use playerid to reflect the column contents
ALTER TABLE `auction_players` CHANGE `name` `playerid` INT;
ALTER TABLE `final_rosters` CHANGE `name` `playerid` INT;
ALTER TABLE `players_won` CHANGE `name` `playerid` INT;
