all:
	@echo "no target"

seed-db:
	cat sql/01-ddl.sql sql/02-dml.sql | psql postgres


post-seed:
	cat post-seed.sql | psql postgres