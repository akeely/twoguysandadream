ALTER TABLE `passwd` DROP PRIMARY KEY;
ALTER TABLE `passwd` ADD `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

ALTER TABLE `passwd` ADD `openid` VARCHAR(256);
