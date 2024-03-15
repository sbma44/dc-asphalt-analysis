#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

rm -f "$(dirname $0)/../results/precomputed_stats.csv"
(cd $(dirname $0)/../../web && npm run distances | grep -v '>' | grep '.' > /tmp/distances.txt)
cat /tmp/distances.txt | while read DISTANCE; do
    echo "Precomputing stats for $DISTANCE"

    echo "
    WITH school_stats AS (
        SELECT
            count(s.*) as num_schools,
            SUM(enrollment) as enrollment
        FROM schools s
        WHERE
            LOWER(grades) != 'adult' AND
            st_distance(cast(s.pt as geography), CAST(ST_SETSRID(ST_MAKEPOINT(${PLANT_LOCATION}), 4326) AS GEOGRAPHY)) <= ${DISTANCE}
    ),
    housing_stats AS (
        SELECT
            TRUNC(SUM(GREATEST(housing_unit_count, residential_unit_count))) AS residential_unit_count
        FROM addresses
        WHERE
            st_distance(cast(pt as geography), cast(st_setsrid(st_makepoint(${PLANT_LOCATION}), 4326) as geography)) <= ${DISTANCE}
    )
    SELECT
        $DISTANCE as distance_m,
        school_stats.num_schools AS num_schools,
        school_stats.enrollment AS enrollment,
        housing_stats.residential_unit_count AS residential_unit_count
    FROM school_stats, housing_stats;" | $PSQL -t -A -F',' >> "$(dirname $0)/../results/precomputed_stats.csv"
done