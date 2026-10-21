-- 04_marts.sql
-- Aggregated tables for analysis. Raw counts are stored (not percentages)
-- so rates can be recomputed correctly at any aggregation level.

USE WAREHOUSE ipl_wh;
USE DATABASE ipl;

-- Batting by season and phase.
-- Balls faced excludes wides (not playable) but includes no-balls (playable).
-- Note: player_out = batter misses non-strikers run out; a small undercount of dismissals.
CREATE OR REPLACE TABLE marts.batter_phase_stats AS
SELECT season, batter, phase,
  COUNT_IF(NOT is_wide)                      AS balls_faced,
  SUM(batter_runs)                           AS runs,
  COUNT_IF(NOT is_wide AND batter_runs = 0)  AS dot_balls,
  COUNT_IF(batter_runs IN (4, 6))            AS boundaries,
  COUNT_IF(player_out = batter)              AS dismissals
FROM staging.deliveries
GROUP BY 1, 2, 3;

-- Bowling by season and phase.
-- Byes and leg byes are not charged to the bowler; run outs and retirements are not bowler wickets.
CREATE OR REPLACE TABLE marts.bowler_phase_stats AS
SELECT season, bowler, phase,
  COUNT_IF(NOT is_wide AND NOT is_noball)     AS legal_balls,
  SUM(batter_runs + wide_runs + noball_runs)  AS runs_conceded,
  COUNT_IF(total_runs = 0)                    AS dot_balls,
  COUNT_IF(wicket_kind IS NOT NULL
    AND wicket_kind NOT IN ('run out', 'retired hurt', 'retired out', 'obstructing the field')) AS wickets
FROM staging.deliveries
GROUP BY 1, 2, 3;

-- Rolling strike rate over each batter's last 5 innings.
-- Sums runs and balls across the window instead of averaging strike rates,
-- so short innings don't carry the same weight as long ones.
CREATE OR REPLACE TABLE marts.batter_form AS
WITH inns AS (
  SELECT match_id, match_date, batter,
         SUM(batter_runs) AS runs, COUNT_IF(NOT is_wide) AS balls
  FROM staging.deliveries
  GROUP BY 1, 2, 3
)
SELECT *,
  100.0 * SUM(runs)  OVER (PARTITION BY batter ORDER BY match_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW)
  / NULLIF(SUM(balls) OVER (PARTITION BY batter ORDER BY match_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW), 0)
  AS rolling_sr_5
FROM inns;
