#!/usr/bin/env bash

set -e

SQLITE=sqlite3
DBFILE=data/covid.db
DBCREATEFILE=src/dbcreate.sql

start_ts=`date +%s.%N`

echo "Using $SQLITE..."

if [[ -f "$DBFILE" ]]
then
	echo "Deleting already existing database $DBFILE..." 2>&1
	rm -f "$DBFILE"
fi

echo "Creating database $DBFILE from script $DBCREATEFILE..." 2>&1
"$SQLITE" "$DBFILE" < "$DBCREATEFILE"

end_ts=`date +%s.%N`
runtime=`echo "$end_ts - $start_ts" | bc -l`
echo "Done in $runtime s."
