#!/bin/sh

set -e

tmpfile=$(mktemp)
marker=loaded/$(basename $1)

mkdir -p loaded/

if [ -f "$marker" ] ; then
  exit 0
fi

psql -X >$tmpfile <<EOF
\COPY github_events (repo_id, data) FROM PROGRAM 'gzip -dc $*'
EOF

if [ -s $tmpfile ]; then
  events=$(awk '{print $2}' $tmpfile)
  size=$(gzip -l $* | tail -n 1 | awk '{printf "%d",$2}')
  psql -tAX -c "INSERT INTO ingest (events, size) VALUES ($events, $size)" >/dev/null
  timestamp=$(date +"%F %T")  
  #timestamp=$(date +"%s")
  rate=$(psql -tAX -c " SELECT pg_size_pretty((60*sum(size)/(extract(epoch from (max(ingest_time)-min(ingest_time)))))::bigint) FROM (SELECT * FROM ingest WHERE ingest_time >= now() - interval '1 hour' ORDER BY ingest_time DESC LIMIT 20) ingests")
  eventrate=$(psql -tAX -c "SELECT sum(events) FROM (SELECT events FROM ingest WHERE ingest_time >= now() - interval '1 hour' ORDER BY ingest_time DESC LIMIT 20) ingests")
  echo "Ingested $events GitHub events ($rate/minute)"
  touch $marker
  rm $tmpfile
else
  rm $tmpfile
  exit 1
fi
