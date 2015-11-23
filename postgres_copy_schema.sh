pg_dump  --schema='mychef' carneirao | sed 's/mychef/mychef_test/g' | psql -d carneirao
