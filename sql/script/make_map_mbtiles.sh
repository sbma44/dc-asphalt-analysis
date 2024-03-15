#!/bin/bash

set -eu -o pipefail
set -x

source "$(dirname $0)/conf.sh"

rm -f /tmp/addresses.geojson
echo "
SELECT
    ADDRESS AS address,
    ST_DISTANCE(CAST(pt AS GEOGRAPHY), CAST(ST_SETSRID(ST_MAKEPOINT(${PLANT_LOCATION}), 4326) AS GEOGRAPHY)) AS dist_from_plant_m,
    residential_type,
    GREATEST(residential_unit_count, housing_unit_count) as unit_count,
    created_date,
    ST_X(pt) AS lng,
    ST_Y(pt) AS lat
FROM addresses
WHERE
    ST_DISTANCE(CAST(pt AS GEOGRAPHY), CAST(ST_SETSRID(ST_MAKEPOINT(${PLANT_LOCATION}), 4326) AS GEOGRAPHY)) <= 5100;" | $PSQL -t -A -F$'\t' >> /tmp/map-addresses.tsv

python3 $(dirname $0)/py/tippecanoe-prep.py /tmp/map-addresses.tsv > /tmp/map-addresses.ldgeojson
tippecanoe -f -o /tmp/map-addresses.mbtiles -zg --extend-zooms-if-still-dropping --drop-densest-as-needed /tmp/map-addresses.ldgeojson