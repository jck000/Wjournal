-- Convert schema '/home/fuzzix/projects/Wjournal/bin/../sql/Wjournal-Schema-2-MySQL.sql' to 'Wjournal::Schema v3':;

BEGIN;

ALTER TABLE post ADD COLUMN disable_comment integer NULL DEFAULT 0;


COMMIT;

