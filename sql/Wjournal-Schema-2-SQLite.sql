-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Jul  9 21:55:31 2013
-- 

BEGIN TRANSACTION;

--
-- Table: poster
--
DROP TABLE poster;

CREATE TABLE poster (
  uid INTEGER PRIMARY KEY NOT NULL,
  admin integer NOT NULL,
  login varchar(14) NOT NULL,
  name varchar(20) NOT NULL
);

--
-- Table: post
--
DROP TABLE post;

CREATE TABLE post (
  id INTEGER PRIMARY KEY NOT NULL,
  uid integer NOT NULL,
  format varchar(8) NOT NULL,
  is_pending integer NOT NULL DEFAULT 1,
  is_deleted integer DEFAULT 0,
  preview_token char(36) NOT NULL,
  published_date integer NOT NULL,
  subject text NOT NULL,
  text text NOT NULL,
  FOREIGN KEY (uid) REFERENCES poster(uid) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX post_idx_uid ON post (uid);

--
-- Table: comment
--
DROP TABLE comment;

CREATE TABLE comment (
  id INTEGER PRIMARY KEY NOT NULL,
  post_id integer NOT NULL,
  name text NOT NULL,
  approved integer NOT NULL DEFAULT 0,
  date integer NOT NULL,
  email text NOT NULL,
  website text,
  two_cents text NOT NULL,
  FOREIGN KEY (post_id) REFERENCES post(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX comment_idx_post_id ON comment (post_id);

COMMIT;
