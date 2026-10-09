# pgbench-tpcc-like

A more practical approach to the rather scientific TPC-C benchmark, to utilize Postgres better for the more daily
benchmarking and hardware validation purposes.

**This is NOT an implementation of the official [TPC-C](https://www.tpc.org/tpc_documents_current_versions/current_specifications5.asp)
workload and should not be referred to as one!**

## The why

For ages Postgres DBA-s have used the `pgbench` for quick hardware / config validation...but sadly all default
pgbench transaction modes doing writing (*tpcb-like* and *simple-update*) are abnormally write-heavy and test
basically only the *key-value* access scenario...which mostly is not very real-life at all for a RDBMS.

TPC-C is already more real-life...but sadly the common benchmarking frameworks supporting it are often:
* Overly complex / generic (to support other DB engines as well)
* GUI-controlled
* Bring in a bunch of dependencies
* Customizations require knowing some less-known scripting language like Tcl or Lua, or actual programming in Java etc,
  which can be a mood killer for sure for a quick test
* Make it hard to estimate the output DB size
* Don't allow to dynamically increase of the dataset / warehouse count

# Implementation details

* No external benchmarking toolkits required
* Uses a mix of SQL, PL/pgSQL and pgbench scripting - meaning easy modifications for anyone "friendly" with Postgres
* Data population designed to be "additive" and parallel
* Fast dataset population, a la generates_series()
* Tables not duplicated "per warehouse"
* Limited randomness on "warehouse" selection - only the last 20% of warehouses are active (by default)
* 1 warehouse = 1x 01_init_data.pgbench execution = ~100MiB of data
* A few secondary indexes have been added to be more realistic (TPC-C spec only has PK/UQ-s)
* Weights can easily be adjusted to steer the testing towards, say, more reads
* Supports very long runtimes with more than 2B+ (64-bit IDs) orders 

# Running

```
git clone https://github.com/kmoppel/pgbench-tpcc-like.git && cd pgbench-tpcc-like 

createdb tpcc

psql -f 00_schema.sql tpcc 

# Init dataset with a size of ~40GB. 4*100=400 "warehouses" (1 WH ~ 110MB of data and indexes)
pgbench -n -f 01_init_data.pgbench -c 4 -t 100 tpcc 

# Ensure stats collected
vacuumdb --analyze -j 4 --schema public tpcc

# Ensure pg_stat_statements, reset stats
psql -c "create extension if not exists pg_stat_statements" \
  -c "select pg_stat_reset(), pg_stat_reset_shared(), pg_stat_statements_reset()" tpcc

# Test for 30min with 32 clients
# PS Warehouse count / scale needs to be much higher than client count, not to get throttled by locking!
# PS2 Need to explictly set ACTIVE_WHS! Here only 30% of warehouses are being actively used
# PS3 Need to explicitly set NUM_WHS to the loaded warehouse count (= #executions of 01_init_data,
#     i.e. clients*transactions of the init step; 4*100=400 above). The scripts pick the warehouse
#     client-side from this, so it must match the data or w_id will go out of range.
pgbench -n -c 32 -T 1800 -P 300 -D ACTIVE_WHS=0.3 -D NUM_WHS=400 \
  -f new_order.pgbench@45 -f payment_transaction.pgbench@43 -f order_status.pgbench@4 \
  -f delivery_transaction.pgbench@4 -f stock_check.pgbench@4 tpcc

# PS4 Each script wraps its work in a single BEGIN/COMMIT, so the run does ~1 DB commit per
#     transaction (not one per statement) - far fewer WAL flushes.
# PS5 Once warmed up, re-run with `-M prepared` to skip per-statement re-parsing
#     (extended-protocol prepared statements). Use it only on the benchmark run, NOT on the
#     one-shot init step above:
pgbench -n -M prepared -c 32 -T 1800 -P 300 -D ACTIVE_WHS=0.3 -D NUM_WHS=400 \
  -f new_order.pgbench@45 -f payment_transaction.pgbench@43 -f order_status.pgbench@4 \
  -f delivery_transaction.pgbench@4 -f stock_check.pgbench@4 tpcc

# Analyze results / stats ...
```

# Contributing

Feedback and PR-s very much appreciated!

# TODO

* Investigate if can support running in `--protocol=prepared` mode as well.
* Add a Dockerfile + auto build 
