#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

for DISTANCE in 250 500 750 1000 1250; do
    echo "
    select
        cast(date_part('Y', created_date) as integer) >= 2019 as since_2019,
        TRUNC(SUM(housing_unit_count)) as housing_unit_sum,
        TRUNC(SUM(residential_unit_count)) as residential_unit_sum,
        TRUNC(SUM(GREATEST(housing_unit_count, residential_unit_count))) as units from addresses
    where st_distance(cast(pt as geography), cast(st_setsrid(st_makepoint(${PLANT_LOCATION}), 4326) as geography)) <= ${DISTANCE}
    group by 1 order by 1 asc;" | $PSQL > $(dirname $0)/results/units_near_plant_${DISTANCE}.tsv
done