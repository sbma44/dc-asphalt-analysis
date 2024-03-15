#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

echo "DROP TABLE IF EXISTS school_export;" | $PSQL
echo "CREATE TABLE school_export AS
    SELECT *,
    ST_DISTANCE(CAST(pt AS GEOGRAPHY), CAST(ST_SETSRID(ST_MAKEPOINT(${PLANT_LOCATION}), 4326) AS GEOGRAPHY)) AS dist_from_plant_m
FROM schools;" | $PSQL

ogr2ogr -f "GeoJSON" /tmp/school_export.geojson PG:"host=$PG_HOST dbname=$DB_NAME user=postgres password=$PGPASSWORD port=5432" "school_export(pt)"