-- Convert schema '/home/fuzzix/projects/Wjournal/bin/../sql/Wjournal-Schema-2-SQLite.sql' to '/home/fuzzix/projects/Wjournal/bin/../sql/Wjournal-Schema-3-SQLite.sql':;

BEGIN;

ALTER TABLE post ADD COLUMN disable_comment integer DEFAULT 0;


COMMIT;

