"""
Combine Cricsheet's per-match IPL JSON files into one newline-delimited JSON file
for a single upload to a Snowflake internal stage.

Usage:
    1. Download https://cricsheet.org/downloads/ipl_json.zip
    2. Unzip into data/ipl_json/
    3. python scripts/build_ndjson.py

Each output line is one match. The match ID (the Cricsheet filename) is added
as a top-level "match_id" field so it survives the load into a VARIANT column.
"""
import glob
import json
import os

SRC = "data/ipl_json/*.json"
OUT = "data/ipl_matches.ndjson"

files = sorted(glob.glob(SRC))
with open(OUT, "w") as out:
    for path in files:
        with open(path) as f:
            match = json.load(f)
        match["match_id"] = os.path.basename(path).replace(".json", "")
        out.write(json.dumps(match) + "\n")

print(f"Wrote {len(files)} matches to {OUT}")
