-- MySQL dump 10.13  Distrib 5.6.19, for debian-linux-gnu (x86_64)
--
-- Host: akeely-auction.cwp74fsixexb.us-east-1.rds.amazonaws.com    Database: auction
-- ------------------------------------------------------
-- Server version	5.6.21-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auction_players`
--

DROP TABLE IF EXISTS `auction_players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `auction_players` (
  `name` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `price` varchar(5) NOT NULL DEFAULT '',
  `team` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `time` varchar(20) NOT NULL DEFAULT '',
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `rfa_override` enum('WAIT','YES','NO','NA') NOT NULL DEFAULT 'NA' COMMENT 'in RFA draft, ''won'' players can be overriden by the previous owner',
  PRIMARY KEY (`name`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `league` varchar(50) NOT NULL DEFAULT '',
  `category` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`league`,`category`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `contracts`
--

DROP TABLE IF EXISTS `contracts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `contracts` (
  `player` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `team` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `type` varchar(5) NOT NULL DEFAULT '',
  `total_years` varchar(5) NOT NULL DEFAULT '',
  `years_left` varchar(5) NOT NULL DEFAULT '',
  `current_cost` varchar(5) NOT NULL DEFAULT '',
  `broken` enum('Y','N') NOT NULL DEFAULT 'N' COMMENT '''Y'' is contract is broken and owner paid',
  `penalty` tinyint(4) DEFAULT NULL COMMENT 'Should be POSITIVE; only populated if contract is broken',
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `locked` enum('no','yes') NOT NULL DEFAULT 'no',
  PRIMARY KEY (`player`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `fa_keepers`
--

DROP TABLE IF EXISTS `fa_keepers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `fa_keepers` (
  `league` varchar(50) NOT NULL DEFAULT '',
  `position` char(3) NOT NULL DEFAULT '',
  `price` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`league`,`position`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `final_rosters`
--

DROP TABLE IF EXISTS `final_rosters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `final_rosters` (
  `name` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `price` varchar(5) NOT NULL DEFAULT '',
  `team` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `time` varchar(16) NOT NULL DEFAULT '',
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  KEY `name` (`name`),
  KEY `FINAL_ROSTERS_INDEX` (`team`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `keeper_slots`
--

DROP TABLE IF EXISTS `keeper_slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `keeper_slots` (
  `league` varchar(50) NOT NULL DEFAULT '',
  `min` tinyint(4) NOT NULL DEFAULT '0',
  `max` tinyint(4) NOT NULL DEFAULT '0',
  `number` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`league`,`min`,`max`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `leagues`
--

DROP TABLE IF EXISTS `leagues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `leagues` (
  `name` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `password` varchar(25) NOT NULL DEFAULT '',
  `owner` varchar(50) NOT NULL DEFAULT '',
  `draft_type` enum('auction','snake','rfa') NOT NULL DEFAULT 'auction',
  `draft_status` enum('open','closed','paused') NOT NULL DEFAULT 'open',
  `keepers_locked` enum('no','yes') NOT NULL DEFAULT 'no',
  `sport` enum('baseball','football','basketball') NOT NULL DEFAULT 'baseball',
  `categories` varchar(200) DEFAULT NULL,
  `positions` varchar(100) DEFAULT NULL,
  `max_teams` char(3) NOT NULL DEFAULT '',
  `salary_cap` varchar(5) NOT NULL DEFAULT '',
  `auction_length` double NOT NULL,
  `bid_time_ext` double NOT NULL,
  `bid_time_buff` double NOT NULL,
  `tz_offset` int(2) NOT NULL DEFAULT '0' COMMENT 'Hours',
  `login_ext` int(3) NOT NULL DEFAULT '0' COMMENT 'Minutes',
  `sessions_flag` enum('yes','no') NOT NULL DEFAULT 'yes',
  `contractA` varchar(5) DEFAULT NULL COMMENT '# of contracts | length',
  `contractB` varchar(5) DEFAULT NULL COMMENT '# of contracts | length',
  `contractC` varchar(5) DEFAULT NULL COMMENT '# of contracts | length',
  `keeper_increase` char(3) NOT NULL DEFAULT '0' COMMENT 'percent',
  `fa_keeper_prices` varchar(25) DEFAULT NULL COMMENT 'QB|RB|WR|TE|K|DEF or C|1B|2B|3B|SS|OF|DH|SP|RP',
  `previous_league` varchar(50) DEFAULT NULL COMMENT 'Name of previous league if this is an inherited keeper league',
  PRIMARY KEY (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `passwd`
--

DROP TABLE IF EXISTS `passwd`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `passwd` (
  `name` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `passwd` varchar(16) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  `email` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  PRIMARY KEY (`name`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players`
--

DROP TABLE IF EXISTS `players`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `players` (
  `playerid` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(60) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `sport` enum('baseball','football') NOT NULL DEFAULT 'baseball',
  `position` varchar(15) NOT NULL DEFAULT '',
  `team` varchar(6) NOT NULL DEFAULT '',
  `rank` int(11) NOT NULL DEFAULT '0',
  `active` int(11) NOT NULL,
  `yahooid` int(11) NOT NULL,
  PRIMARY KEY (`playerid`),
  KEY `name` (`name`,`sport`),
  KEY `active` (`active`)
) ENGINE=MyISAM AUTO_INCREMENT=116517 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `players_won`
--

DROP TABLE IF EXISTS `players_won`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `players_won` (
  `name` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `price` float NOT NULL DEFAULT '0',
  `team` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `time` varchar(16) NOT NULL DEFAULT '',
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `rfa_override` enum('WAIT','YES','NO','NA') NOT NULL DEFAULT 'NA',
  PRIMARY KEY (`name`,`league`),
  KEY `PLAYERS_WON_INDEX` (`team`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `position_relations`
--

DROP TABLE IF EXISTS `position_relations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `position_relations` (
  `position` varchar(10) NOT NULL DEFAULT '',
  `rel_position` varchar(10) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `positions`
--

DROP TABLE IF EXISTS `positions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `positions` (
  `league` varchar(50) NOT NULL DEFAULT '',
  `position` varchar(10) NOT NULL DEFAULT '',
  PRIMARY KEY (`league`,`position`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sessions` (
  `IP` varchar(20) DEFAULT NULL,
  `owner` varchar(20) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  `password` varchar(20) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  `sess_id` varchar(15) NOT NULL DEFAULT '',
  `team` varchar(20) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  `sport` varchar(15) DEFAULT NULL,
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs DEFAULT NULL,
  PRIMARY KEY (`sess_id`),
  UNIQUE KEY `IP` (`IP`,`owner`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tags`
--

DROP TABLE IF EXISTS `tags`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tags` (
  `player` varchar(6) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `team` varchar(30) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `type` char(1) NOT NULL DEFAULT '',
  `league` varchar(40) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `cost` varchar(5) NOT NULL DEFAULT '',
  `locked` enum('yes','no') NOT NULL DEFAULT 'no',
  `active` enum('yes','no') NOT NULL DEFAULT 'yes',
  UNIQUE KEY `player` (`player`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `targets`
--

DROP TABLE IF EXISTS `targets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `targets` (
  `playerid` int(11) NOT NULL DEFAULT '0',
  `owner` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `league` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `price` double NOT NULL DEFAULT '0'
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teams`
--

DROP TABLE IF EXISTS `teams`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `teams` (
  `owner` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `name` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `league` varchar(50) CHARACTER SET latin1 COLLATE latin1_general_cs NOT NULL DEFAULT '',
  `num_adds` smallint(5) NOT NULL DEFAULT '0',
  `sport` enum('baseball','football','basketball') NOT NULL DEFAULT 'baseball',
  `money_plusminus` float NOT NULL DEFAULT '0',
  PRIMARY KEY (`owner`,`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `test`
--

DROP TABLE IF EXISTS `test`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `test` (
  `name` varchar(20) NOT NULL DEFAULT '',
  `id` varchar(20) NOT NULL DEFAULT ''
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trading_block`
--

DROP TABLE IF EXISTS `trading_block`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `trading_block` (
  `player` int(11) NOT NULL,
  `league` varchar(50) NOT NULL,
  `askingprice` int(11) NOT NULL,
  `owner` varchar(50) NOT NULL,
  KEY `trade_block_index` (`league`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2015-02-15 21:53:38
