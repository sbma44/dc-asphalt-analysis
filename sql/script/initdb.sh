#!/bin/bash

set -eu -o pipefail

source "$(dirname $0)/conf.sh"

dropdb --if-exists -U postgres -h "$PG_HOST" "$DB_NAME"
createdb -U postgres -h "$PG_HOST" "$DB_NAME"

echo "CREATE EXTENSION postgis;" | $PSQL