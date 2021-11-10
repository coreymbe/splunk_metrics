#!/bin/bash

# ./post_metrics /path/to/metrics 3

DATA_DIR=$1
RETENTION_DAYS="${2:-7}"

echo "Extracting data from tarballs..."
find "$DATA_DIR" -type f -ctime -"${RETENTION_DAYS}" -name "*.bz2" -execdir tar jxf "{}" \; 2>/dev/null
find "$DATA_DIR" -type f -ctime -"${RETENTION_DAYS}" -name "*.gz" -execdir tar xf "{}" \; 2>/dev/null

echo "Deleting json files past ${RETENTION_DAYS} retention_days..."
NUM_DEL=$(find "$DATA_DIR" -type f -mtime +"${RETENTION_DAYS}" -iname "*.json" -delete -print | wc -l)
echo "Deleted $NUM_DEL files past retention_days"

echo "Posting data..."
sleep 2
echo "...grab some coffee this may take a while..."
sleep 1
for f in $(find "$DATA_DIR" -name "*.json")
  do cat $f | /opt/puppetlabs/bin/puppet splunk_metrics --sourcetype puppet:metrics --pe_metrics -d
done
