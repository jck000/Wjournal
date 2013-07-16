-- Convert schema '/home/fuzzix/projects/Wjournal/bin/../sql/Wjournal-Schema-2-PostgreSQL.sql' to '/home/fuzzix/projects/Wjournal/bin/../sql/Wjournal-Schema-3-PostgreSQL.sql':;

BEGIN;

ALTER TABLE post ADD COLUMN disable_comment integer DEFAULT 0;


COMMIT;

