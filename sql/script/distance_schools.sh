#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

SCHOOLS_SUM=""
for DISTANCE in 250 500 750 1000 1250; do
    echo "
    select
        name,
        enrollment,
        grades,
        type
    from schools
    where
    LOWER(grades) != 'adult' AND
    st_intersects(cast(pt as geography), st_buffer(cast(st_setsrid(st_makepoint(${PLANT_LOCATION}), 4326) as geography), ${DISTANCE}));" | $PSQL -t -A -F','> $(dirname $0)/results/schools_near_plant_${DISTANCE}.tsv

    SCHOOLS_SUM="${SCHOOLS_SUM}\n
    ${DISTANCE}\t$(echo "
    select sum(enrollment) from schools
    where LOWER(grades) != 'adult' AND
    st_intersects(cast(pt as geography), st_buffer(cast(st_setsrid(st_makepoint(${PLANT_LOCATION}), 4326) as geography), ${DISTANCE}));" | $PSQL -t -A -F',')"
done

echo ${SCHOOLS_SUM} > $(dirname $0)/results/schools_near_plant_sum.tsv
