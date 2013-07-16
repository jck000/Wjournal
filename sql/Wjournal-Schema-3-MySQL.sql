-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Tue Jul 16 18:54:34 2013
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS `poster`;

--
-- Table: `poster`
--
CREATE TABLE `poster` (
  `uid` integer NOT NULL,
  `admin` integer NOT NULL,
  `login` varchar(14) NOT NULL,
  `name` varchar(20) NOT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `post`;

--
-- Table: `post`
--
CREATE TABLE `post` (
  `id` integer NOT NULL auto_increment,
  `uid` integer NOT NULL,
  `format` varchar(8) NOT NULL,
  `is_pending` integer NOT NULL DEFAULT 1,
  `is_deleted` integer NULL DEFAULT 0,
  `disable_comment` integer NULL DEFAULT 0,
  `preview_token` char(36) NOT NULL,
  `published_date` integer NOT NULL,
  `subject` text NOT NULL,
  `text` text NOT NULL,
  INDEX `post_idx_uid` (`uid`),
  PRIMARY KEY (`id`),
  CONSTRAINT `post_fk_uid` FOREIGN KEY (`uid`) REFERENCES `poster` (`uid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS `comment`;

--
-- Table: `comment`
--
CREATE TABLE `comment` (
  `id` integer NOT NULL auto_increment,
  `post_id` integer NOT NULL,
  `name` text NOT NULL,
  `approved` integer NOT NULL DEFAULT 0,
  `date` integer NOT NULL,
  `email` text NOT NULL,
  `website` text NULL,
  `two_cents` text NOT NULL,
  INDEX `comment_idx_post_id` (`post_id`),
  PRIMARY KEY (`id`),
  CONSTRAINT `comment_fk_post_id` FOREIGN KEY (`post_id`) REFERENCES `post` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

SET foreign_key_checks=1;

