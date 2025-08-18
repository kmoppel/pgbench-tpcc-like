# pgbench-tpcc

A Pareto approach to the rather scientific TPCC benchmark, to utilize Postgres in a more real-life way, compared to the
default pgbench transaction modes. Uses a mix of pgbench scripting + PL/pgSQL. 

Data population designed to be "additive" and parallel, for faster init.

# Running

```
createdb tpcc

psql -f 0_schema.sql 

# Init dataset with a size of 4*100=400 "warehouses" or ~40GB in size (1 WH ~ 100MB)
pgbench -n -f 1_init_data.pgbench -c 4 -t 100 

psql -c "select pg_stat_reset(), pg_stat_reset_shared()" tpcc

# Test for 30min with 32 clients
# PS Warehouse count / scale needs to be much higher than client count, not to get throttled by locking!
pgbench -n -c 32 -T 1800 -f new_order.pgbench@45 -f payment_transaction.pgbench@43 -f order_status.pgbench@4 -f delivery_transaction.pgbench@4 -f stock_check.pgbench@4 tpcc
```
