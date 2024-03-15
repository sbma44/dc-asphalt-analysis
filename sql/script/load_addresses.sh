#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

if [ ! -f "$(dirname $0)/data/master_address_repository/AddressPT_02272024.zip" ]; then
    echo "No address data found in $(dirname $0)/data/master_address_repository"
    echo "You should download the Master Address Repository data from https://opendata.dc.gov/pages/addressing-in-dc#data"
    exit 1
fi

(cd /tmp && unzip $(dirname $0)/data/master_address_repository/AddressPT_02272024.zip AddressPT_02272024.csv)

echo "
DROP TABLE IF EXISTS addresses;
CREATE TABLE addresses (
    OID_ INT PRIMARY KEY,
    MAR_ID DECIMAL,
    ADDRESS TEXT,
    ADDRESS_NUMBER INT,
    ADDRESS_NUMBER_SUFFIX TEXT,
    STREET_NAME TEXT,
    STREET_TYPE TEXT,
    QUADRANT TEXT,
    ZIPCODE DECIMAL,
    CITY TEXT,
    STATE TEXT,
    COUNTRY TEXT,
    X_COORDINATE DECIMAL,
    Y_COORDINATE DECIMAL,
    LATITUDE DECIMAL,
    LONGITUDE DECIMAL,
    ADDRESS_TYPE TEXT,
    STATUS TEXT,
    ROUTEID TEXT,
    BLOCKKEY TEXT,
    SUBBLOCKKEY TEXT,
    WARD TEXT,
    METADATA_ID DECIMAL,
    NATIONAL_GRID TEXT,
    HAS_SSL BOOLEAN,
    HAS_PLACE_NAME BOOLEAN,
    HAS_CONDO BOOLEAN,
    HAS_RESIDENTIAL_UNIT BOOLEAN,
    STREET_VIEW_URL TEXT,
    RESIDENTIAL_TYPE TEXT,
    PLACEMENT TEXT,
    SSL_ALIGNMENT TEXT,
    BUILDING TEXT,
    SSL TEXT,
    SQUARE TEXT,
    SUFFIX TEXT,
    LOT TEXT,
    MULTIPLE_LAND_SSL TEXT,
    GRID_DIRECTION TEXT,
    HOUSING_UNIT_COUNT DECIMAL,
    RESIDENTIAL_UNIT_COUNT DECIMAL,
    BEFORE_DATE TIMESTAMP,
    BEFORE_DATE_SOURCE TEXT,
    BEGIN_DATE TIMESTAMP,
    BEGIN_DATE_SOURCE TEXT,
    FIRST_KNOWN_DATE TIMESTAMP,
    FIRST_KNOWN_DATE_SOURCE TEXT,
    CREATED_DATE TIMESTAMP,
    CREATED_USER TEXT,
    LAST_EDITED_DATE TIMESTAMP,
    LAST_EDITED_USER TEXT,
    SMD TEXT,
    ANC TEXT
);" | $PSQL

TMP_FILENAME='/tmp/dc_aq_sanitized.csv'
rm -f "$TMP_FILENAME"
python3 "$(dirname $0)/py/sanitize_csv.py" < "/tmp/AddressPT_02272024.csv" > "$TMP_FILENAME"

echo "\copy addresses FROM '${TMP_FILENAME}' with DELIMITER ',' CSV HEADER;" | $PSQL

# indices
for FIELD in FIRST_KNOWN_DATE BEGIN_DATE ADDRESS_TYPE RESIDENTIAL_TYPE; do
    echo "CREATE INDEX addresses_${FIELD}_idx ON addresses(${FIELD});" | $PSQL
done

# geo
echo "alter table addresses add column pt Geometry(Point, 4326);
update addresses set pt=st_setsrid(st_makepoint(cast(longitude as decimal), cast(latitude as decimal)), 4326);
create index addresses_pt_idx ON addresses USING GIST(pt);" | $PSQL