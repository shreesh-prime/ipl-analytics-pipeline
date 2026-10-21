-- 01_setup.sql
-- Warehouse, database, schema layers, file format, and internal stage.

CREATE WAREHOUSE IF NOT EXISTS ipl_wh WAREHOUSE_SIZE = XSMALL AUTO_SUSPEND = 60;
CREATE DATABASE IF NOT EXISTS ipl;
CREATE SCHEMA IF NOT EXISTS ipl.raw;      -- untouched source data
CREATE SCHEMA IF NOT EXISTS ipl.staging;  -- cleaned, one row per delivery
CREATE SCHEMA IF NOT EXISTS ipl.marts;    -- aggregated tables for analysis

USE WAREHOUSE ipl_wh;
USE DATABASE ipl;

CREATE FILE FORMAT IF NOT EXISTS raw.json_fmt TYPE = JSON;
CREATE STAGE IF NOT EXISTS raw.cricsheet_stage FILE_FORMAT = raw.json_fmt;
