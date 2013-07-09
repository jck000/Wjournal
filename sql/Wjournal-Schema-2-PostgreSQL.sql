-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Tue Jul  9 21:55:31 2013
-- 
--
-- Table: poster.
--
DROP TABLE "poster" CASCADE;
CREATE TABLE "poster" (
  "uid" integer NOT NULL,
  "admin" integer NOT NULL,
  "login" character varying(14) NOT NULL,
  "name" character varying(20) NOT NULL,
  PRIMARY KEY ("uid")
);

--
-- Table: post.
--
DROP TABLE "post" CASCADE;
CREATE TABLE "post" (
  "id" serial NOT NULL,
  "uid" integer NOT NULL,
  "format" character varying(8) NOT NULL,
  "is_pending" integer DEFAULT 1 NOT NULL,
  "is_deleted" integer DEFAULT 0,
  "preview_token" character(36) NOT NULL,
  "published_date" integer NOT NULL,
  "subject" text NOT NULL,
  "text" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "post_idx_uid" on "post" ("uid");

--
-- Table: comment.
--
DROP TABLE "comment" CASCADE;
CREATE TABLE "comment" (
  "id" serial NOT NULL,
  "post_id" integer NOT NULL,
  "name" text NOT NULL,
  "approved" integer DEFAULT 0 NOT NULL,
  "date" integer NOT NULL,
  "email" text NOT NULL,
  "website" text,
  "two_cents" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "comment_idx_post_id" on "comment" ("post_id");

--
-- Foreign Key Definitions
--

ALTER TABLE "post" ADD CONSTRAINT "post_fk_uid" FOREIGN KEY ("uid")
  REFERENCES "poster" ("uid") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

ALTER TABLE "comment" ADD CONSTRAINT "comment_fk_post_id" FOREIGN KEY ("post_id")
  REFERENCES "post" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

