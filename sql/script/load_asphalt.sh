#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

echo "
DROP TABLE IF EXISTS asphalt;
CREATE TABLE asphalt (
    lng DECIMAL,
    lat DECIMAL,
    name TEXT,
    address TEXT,
    city TEXT,
    state TEXT,
    zip TEXT
);" | $PSQL

TMP_FILENAME='/tmp/asphalt.csv'
rm -f "$TMP_FILENAME"
python3 "$(dirname $0)/py/asphalt_plants.py" > "$TMP_FILENAME"

echo "\copy asphalt FROM '${TMP_FILENAME}' with DELIMITER ',' CSV HEADER;" | $PSQL

echo "ALTER TABLE asphalt ADD id SERIAL PRIMARY KEY;" | $PSQL

# geo
echo "alter table asphalt add column pt Geometry(Point, 4326);
update asphalt set pt=st_setsrid(st_makepoint(cast(lng as decimal), cast(lat as decimal)), 4326);
create index asphalt_pt_idx ON asphalt USING GIST(pt);" | $PSQL