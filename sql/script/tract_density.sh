#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

echo "
DROP TABLE IF EXISTS density_tracts;
CREATE TABLE density_tracts AS
SELECT
    cb.tractce20,
    ST_UNION(cb.wkb_geometry) AS geom,
    SUM(cb.pop20) / (ST_AREA(CAST(ST_UNION(cb.wkb_geometry) AS GEOGRAPHY)) / 1000000.0) as pop_density_km2
FROM
census_block cb
where cb.statefp20 = '11'
GROUP BY cb.tractce20;
" | $PSQL

echo "
DROP TABLE IF EXISTS density_blocks;
CREATE TABLE density_blocks AS
SELECT
    cb.blockce20,
    ST_UNION(cb.wkb_geometry) AS geom,
    SUM(cb.pop20) / (ST_AREA(CAST(ST_UNION(cb.wkb_geometry) AS GEOGRAPHY)) / 1000000.0) as pop_density_km2
FROM
census_block cb
where cb.statefp20 = '11'
GROUP BY cb.blockce20;
" | $PSQL