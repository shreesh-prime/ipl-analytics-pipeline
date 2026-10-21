-- 03_staging_deliveries.sql
-- Flattens nested match JSON (match -> innings -> overs -> deliveries)
-- into one row per delivery. Super overs are excluded.

USE WAREHOUSE ipl_wh;
USE DATABASE ipl;

CREATE OR REPLACE TABLE staging.deliveries AS
SELECT
  m.data:match_id::STRING                   AS match_id,
  m.data:info:dates[0]::DATE                AS match_date,
  YEAR(m.data:info:dates[0]::DATE)          AS season,  -- Cricsheet labels some seasons as "2020/21"
  m.data:info:venue::STRING                 AS venue,
  i.index + 1                               AS innings_no,
  i.value:team::STRING                      AS batting_team,
  o.value:over::INT + 1                     AS over_no,  -- source overs are 0-indexed
  d.index + 1                               AS ball_seq,
  d.value:batter::STRING                    AS batter,
  d.value:bowler::STRING                    AS bowler,
  d.value:runs:batter::INT                  AS batter_runs,
  d.value:runs:total::INT                   AS total_runs,
  COALESCE(d.value:extras:wides::INT, 0)    AS wide_runs,
  COALESCE(d.value:extras:noballs::INT, 0)  AS noball_runs,
  d.value:extras:wides IS NOT NULL          AS is_wide,
  d.value:extras:noballs IS NOT NULL        AS is_noball,
  d.value:wickets[0]:kind::STRING           AS wicket_kind,
  d.value:wickets[0]:player_out::STRING     AS player_out,
  CASE WHEN o.value:over::INT < 6  THEN 'Powerplay'
       WHEN o.value:over::INT < 15 THEN 'Middle'
       ELSE 'Death' END                     AS phase
FROM raw.matches m,
  LATERAL FLATTEN(input => m.data:innings) i,
  LATERAL FLATTEN(input => i.value:overs) o,
  LATERAL FLATTEN(input => o.value:deliveries) d
WHERE i.value:super_over IS NULL;

-- Validation: Virat Kohli scored 973 runs in IPL 2016
SELECT SUM(batter_runs) AS kohli_2016_runs
FROM staging.deliveries
WHERE batter = 'V Kohli' AND season = 2016;  -- expect 973
