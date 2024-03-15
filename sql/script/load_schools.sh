#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

echo "DROP TABLE IF EXISTS schools_charter;
CREATE TABLE schools_charter (
    X NUMERIC,
    Y NUMERIC,
    OBJECTID TEXT,
    NAME TEXT,
    ADDRESS TEXT,
    DIRECTOR TEXT,
    PHONE TEXT,
    AUTHORIZER TEXT,
    GRADES TEXT,
    ENROLLMENT NUMERIC,
    GIS_ID TEXT,
    WEB_URL TEXT,
    AUTHORIZAT TEXT,
    MYSCHOOL TEXT,
    SCHOOL_YEA TEXT,
    LEA_NAME TEXT,
    LEA_ID TEXT,
    SCHOOL_NAM TEXT,
    SCHOOL_ID NUMERIC,
    SCHOOLCODE NUMERIC,
    GRADES_1 TEXT,
    LATITUDE DECIMAL,
    LONGITUDE DECIMAL
);" | $PSQL

xsv select 1-23 $(dirname $0)/schools_charter.csv > /tmp/dc_schools_charter.csv
echo "\copy schools_charter FROM '/tmp/dc_schools_charter.csv' with DELIMITER ',' CSV HEADER;" | $PSQL
echo "
ALTER TABLE schools_charter ADD COLUMN TYPE TEXT DEFAULT 'charter';
CREATE INDEX schools_charter_building_code_idx ON schools_charter (SCHOOL_ID);" | $PSQL

echo "DROP TABLE IF EXISTS schools_public;
CREATE TABLE schools_public (
    X DECIMAL,
    Y DECIMAL,
    NAME TEXT,
    ADDRESS TEXT,
    FACUSE TEXT,
    LEVEL_ TEXT,
    STATUS TEXT,
    PHONE TEXT,
    TOTAL_STUD NUMERIC,
    SSL TEXT,
    GIS_ID TEXT,
    WEB_URL TEXT,
    BLDG_NUM NUMERIC,
    SCH_PROG TEXT,
    CAPITALGAINS TEXT,
    CAPACITY NUMERIC,
    YEAR_BUILT TEXT,
    SQUARE_FOOTAGE TEXT,
    POPULATION_PLAN TEXT,
    LONGITUDE DECIMAL,
    LATITUDE DECIMAL,
    SCHOOL_YEA TEXT,
    LEA_NAME TEXT,
    LEA_ID TEXT,
    SCHOOL_NAM TEXT,
    SCHOOL_ID TEXT,
    GRADES TEXT
);" | $PSQL
xsv select 1-27 $(dirname $0)/schools_public.csv > /tmp/dc_schools_public.csv
echo "\copy schools_public FROM '/tmp/dc_schools_public.csv' with DELIMITER ',' CSV HEADER;" | $PSQL
echo "
ALTER TABLE schools_public ADD COLUMN TYPE TEXT DEFAULT 'public';
CREATE INDEX schools_public_building_code_idx ON schools_public (BLDG_NUM);" | $PSQL

echo "DROP TABLE IF EXISTS enrollment;
CREATE TABLE enrollment (
    building_code NUMERIC,
    school_name TEXT,
    audited_enrollment NUMERIC
);" | $PSQL
xsv select 3,4,6 $(dirname $0)/osse_enrollment_audit.csv > /tmp/dc_schools_enrollment.csv
echo "\copy enrollment FROM '/tmp/dc_schools_enrollment.csv' with DELIMITER ',' CSV HEADER;" | $PSQL
echo "CREATE INDEX enrollment_building_code_idx ON enrollment (building_code);" | $PSQL

echo "
DROP TABLE IF EXISTS schools;
CREATE TABLE schools (
    LONGITUDE DECIMAL,
    LATITUDE DECIMAL,
    BUILDING_CODE TEXT,
    NAME TEXT,
    GRADES TEXT,
    ENROLLMENT NUMERIC,
    TYPE TEXT
);
INSERT INTO schools SELECT s.LONGITUDE, s.LATITUDE, s.SCHOOL_ID, s.NAME, s.GRADES, e.audited_enrollment, s.TYPE FROM schools_charter s INNER JOIN enrollment e ON s.SCHOOL_ID=e.building_code;
INSERT INTO schools SELECT s.LONGITUDE, s.LATITUDE, s.BLDG_NUM, s.NAME, s.GRADES, e.audited_enrollment, s.TYPE FROM schools_public s INNER JOIN enrollment e ON s.BLDG_NUM=e.building_code;
ALTER TABLE schools ADD COLUMN id SERIAL PRIMARY KEY;

CREATE INDEX schools_type_idx ON schools(TYPE);
CREATE INDEX schools_building_code_idx ON schools(BUILDING_CODE);" | $PSQL

# delete duplicates
echo "DELETE FROM
    schools a
        USING schools b
    WHERE
        a.id < b.id
    AND a.NAME=b.NAME AND a.BUILDING_CODE=b.BUILDING_CODE AND a.ENROLLMENT=b.ENROLLMENT and a.TYPE=b.TYPE;" | $PSQL

# geo
echo "alter table schools add column pt Geometry(Point, 4326);
update schools set pt=st_setsrid(st_makepoint(cast(LONGITUDE as decimal), cast(LATITUDE as decimal)), 4326);
create index schools_pt_idx ON schools USING GIST(pt);" | $PSQL