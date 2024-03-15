#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

SHAPEFILE_COUNT="$(ls $(dirname $0)/data/census/*_tract.shp | wc -l)"
if [ "$SHAPEFILE_COUNT" -eq 0 ]; then
    echo "No shapefiles found in $(dirname $0)/data/census"
    echo "You should download block and tract shapefiles for DC/MD/VA from https://www.census.gov/cgi-bin/geo/shapefiles/index.php"
    exit 1
fi

WRITE_MODE="-overwrite"
for f in $(dirname $0)/data/census/*_tract.shp; do
    ogr2ogr -t_srs EPSG:4326 -lco precision=NO ${WRITE_MODE} -nln census_tract -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$PG_HOST' port='5432' user='postgres' password='$PGPASSWORD'" "$f"
    WRITE_MODE="-append"
    echo "finished $f"
done

WRITE_MODE="-overwrite"
for f in $(dirname $0)/data/census/*tabblock20.shp; do
    ogr2ogr -t_srs EPSG:4326 -lco precision=NO ${WRITE_MODE} -nln census_block -nlt PROMOTE_TO_MULTI -f PostgreSQL PG:"dbname='$DB_NAME' host='$PG_HOST' port='5432' user='postgres' password='$PGPASSWORD'" "$f"
    WRITE_MODE="-append"
    echo "finished $f"
done
