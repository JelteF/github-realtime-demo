END_DATE=2019-01-01


.PHONY: setup run ingest-events process-events

run: setup
	tmux new-session \; send-keys 'make ingest-events' C-M \; split-window -h \; send-keys 'make process-events' C-M \;

setup: setup.log

setup.log:
	psql -f rollups.sql
	psql -f github-events.sql
	psql -f github-commits.sql
	psql -f stats.sql
	touch setup.log


ingest-events:
	./ingest-events

process-events:
	./process-events

fetch:
	psql -c "\\COPY (SELECT d::date, h FROM generate_series('2019-01-01', '$(END_DATE)', interval '1 day') d, generate_series(0,23) h) TO STDOUT" | xargs -n 2 -P 32 ./pre-process

fetch-1-day:
	make fetch END_DATE=2019-01-01

fetch-3-days:
	make fetch END_DATE=2019-01-03

fetch-1-week:
	make fetch END_DATE=2019-01-07

fetch-1-month:
	make fetch END_DATE=2019-01-31

fetch-3-month:
	make fetch END_DATE=2019-03-31

fetch-5-month:
	make fetch END_DATE=2019-05-31

clean:
	rm -f *.log
	rm -rf loaded
