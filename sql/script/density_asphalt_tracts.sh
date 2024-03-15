#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

echo "
WITH plant_tracts AS (
    SELECT
        ct.tractce,
        a.id
    FROM
        asphalt a
    JOIN
        census_tract ct
    ON
        st_intersects(a.pt, ct.wkb_geometry)
)
SELECT
    pt.id,
    pt.tractce,
    MAX(a.name) AS name,
    MAX(a.city) AS city,
    MAX(a.state) AS state,
    SUM(cb.pop20) as pop20,
    ST_AREA(CAST(ST_UNION(cb.wkb_geometry) AS GEOGRAPHY)) / 1000000.0 as area_km2,
    SUM(cb.pop20) / (ST_AREA(CAST(ST_UNION(cb.wkb_geometry) AS GEOGRAPHY)) / 1000000.0) as pop_density_km2
FROM
    census_block cb JOIN plant_tracts pt ON cb.tractce20 = pt.tractce
    JOIN asphalt a ON pt.id = a.id
GROUP BY 1, 2
ORDER BY 8 DESC;

" | $PSQL -t -A -F $'\t' > $(dirname $0)/results/density_asphalt_tracts.tsv