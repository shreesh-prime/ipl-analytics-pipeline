-- 02_load_raw.sql
-- Source: Cricsheet IPL ball-by-ball JSON (cricsheet.org), 1,243 matches, 2008-2026.
-- The per-match files were combined into one newline-delimited JSON file
-- (ipl_matches.ndjson, one match per line, match_id added from the filename)
-- and uploaded to the internal stage.

USE WAREHOUSE ipl_wh;
USE DATABASE ipl;

CREATE OR REPLACE TABLE raw.matches (data VARIANT);

COPY INTO raw.matches
FROM @raw.cricsheet_stage
FILE_FORMAT = (FORMAT_NAME = 'raw.json_fmt');

-- Expect 1,243 rows, one per match
SELECT COUNT(*) AS match_count FROM raw.matches;
