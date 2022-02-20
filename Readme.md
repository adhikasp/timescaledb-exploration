## Comparison between databases

| Features             | MySQL 5.7 | MySQL 8.x | TimeScaleDB | ScyllaDB |
|----------------------|-----------|-----------|-------------|----------|
| Atomic transaction   | Yes       | Yes       | Yes         | No       |
| Instant alter        | No        | Yes       | Yes         | Yes      |
| Background indexing  | No        | No        | Yes         | Yes      |
| Parallel scan query  | No        | No        | Yes         | Yes      |
| Data compaction      | No        | No        | Yes         | Yes      |
| Data TTL             | No        | No        | Yes         | Yes      |
| Analytics-like query | No        | No        | Yes, continuous aggregate | Yes, realtime query |
| Multi node sharding  | No        | No        | Yes, with master node | Yes, fully peer-to-peer |
| Multiple indexes     | Yes       | Yes       | Yes         | Kinda, use GSI / materialized view |

## Query time

```sql
SELECT sum(total_fee), count(*) from transactions WHERE merchant_id = 'merchant-1';
```

| Database                           | Time            |
|------------------------------------|-----------------|
| Mysql 8.0                          | 6 min 52.35 sec |
| TimescaleDB (raw table query)      | 0 min 27 sec    |
| TimescaleDB (continuous aggregate) | 35 ms           |

# Setup

You must have this installed before hand.

```
sudo apt-get install -y postgresql-client
pip3 install progressbar2 faker
go get github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy
```

Starting postgresql with timescaledb extension

```
docker-compose up -d
```

Create table and populate data

```
./command.sh
```

# 1 million dataset

CSV data generation 2:17  
Insert 3:52  

Raw data size 314MB  
DB size 1.0GB  
postgresql total size 2.1GB  

# 10 million dataset

CSV data generation 21:53  
DB insert 06:50:47  

Raw data size 3.1G  
DB size 8.95GB  
postgresql total size 10GB  

# 10 million dataset 2nd run

CSV data generation 22:15  
DB Insert 3:28:49  

Raw data size 3.1G  
DB size 10.8G  
postgresql total size 12G  

798 ingestion / second

# 10 million dataset 3rd run

Using timescaledb-parallel-copy

CSV data 12:00  
DB Insert 26:24  

Raw data size 3.1G  
DB size 10.8G  
postgresql total size 12G  

6243.59/sec (overall)  

# 10 million dataset 4th run 

Using timescale managed db

DB insert 12:28  
row rate 13291.66/sec (overall)  

# 30 million dataset

DB size 33.8G  
DB insert 1:33:0  
row rate 5368.28/sec (overall)  

# Query direct hypertables vs continous aggregate

```
exploration=# SELECT sum(total_fee), count(*) from transactions WHERE merchant_id = 'merchant-1';
    sum     |  count
------------+---------
 3634888528 | 7997931
(1 row)

Time: 27095.767 ms (00:27.096)
exploration=# SELECT sum(total_fee), sum(transaction_count) from transactions_daily WHERE merchant_id = 'merchant-1';
    sum     |   sum
------------+---------
 3634888528 | 7997931
(1 row)

Time: 35.236 ms
```


## Query plan

```

                                                                           QUERY PLAN

----------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=576147.59..576147.60 rows=1 width=16) (actual time=25809.234..25890.886 rows=1 loops=1)
   ->  Gather  (cost=576147.47..576147.58 rows=1 width=16) (actual time=25807.713..25890.863 rows=2 loops=1)
         Workers Planned: 1
         Workers Launched: 1
         ->  Partial Aggregate  (cost=575147.47..575147.48 rows=1 width=16) (actual time=25647.979..25647.988 rows=1 loops=2)
               ->  Parallel Append  (cost=0.00..551612.94 rows=4706906 width=4) (actual time=3387.836..25328.005 rows=3998966 loops=2)
                     ->  Parallel Seq Scan on _hyper_1_6_chunk  (cost=0.00..41138.08 rows=367138 width=4) (actual time=3432.692..7069.980 rows=623089 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155930
                     ->  Parallel Seq Scan on _hyper_1_7_chunk  (cost=0.00..41111.36 rows=366399 width=4) (actual time=2.823..4066.629 rows=622395 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 156118
                     ->  Parallel Seq Scan on _hyper_1_10_chunk  (cost=0.00..41100.82 rows=366554 width=4) (actual time=3.176..3555.384 rows=623210 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155094
                     ->  Parallel Seq Scan on _hyper_1_8_chunk  (cost=0.00..41099.74 rows=366774 width=4) (actual time=4.211..3651.592 rows=622577 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155716
                     ->  Parallel Seq Scan on _hyper_1_11_chunk  (cost=0.00..41084.60 rows=365761 width=4) (actual time=2.423..3705.161 rows=621761 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 156240
                     ->  Parallel Seq Scan on _hyper_1_4_chunk  (cost=0.00..41084.55 rows=366835 width=4) (actual time=4.753..1680.699 rows=311234 loops=2)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 77764
                     ->  Parallel Seq Scan on _hyper_1_9_chunk  (cost=0.00..41075.29 rows=365885 width=4) (actual time=1.641..3825.738 rows=622025 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155798
                     ->  Parallel Seq Scan on _hyper_1_5_chunk  (cost=0.00..41055.49 rows=365629 width=4) (actual time=1.191..3863.313 rows=621332 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 156110
                     ->  Parallel Seq Scan on _hyper_1_1_chunk  (cost=0.00..41050.95 rows=365555 width=4) (actual time=0.046..3474.942 rows=621695 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155674
                     ->  Parallel Seq Scan on _hyper_1_3_chunk  (cost=0.00..41039.31 rows=365954 width=4) (actual time=1.335..3160.270 rows=621807 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155339
                     ->  Parallel Seq Scan on _hyper_1_13_chunk  (cost=0.00..41011.42 rows=365985 width=4) (actual time=1.372..3259.743 rows=621492 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155125
                     ->  Parallel Seq Scan on _hyper_1_2_chunk  (cost=0.00..41011.41 rows=364513 width=4) (actual time=0.708..3329.581 rows=620973 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 155643
                     ->  Parallel Seq Scan on _hyper_1_12_chunk  (cost=0.00..23502.49 rows=209699 width=4) (actual time=0.040..133.619 rows=356103 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 88956
                     ->  Parallel Seq Scan on _hyper_1_14_chunk  (cost=0.00..11712.90 rows=104225 width=4) (actual time=3342.976..3405.834 rows=177004 loops=1)
                           Filter: (merchant_id = 'merchant-1'::text)
                           Rows Removed by Filter: 44799
 Planning Time: 2.068 ms
 JIT:
   Functions: 118
   Options: Inlining true, Optimization true, Expressions true, Deforming true
   Timing: Generation 55.473 ms, Inlining 145.139 ms, Optimization 4045.574 ms, Emission 2584.786 ms, Total 6830.972 ms
 Execution Time: 25919.706 ms
(54 rows)




                                                                                                                    QUERY PLAN

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=395.86..395.87 rows=1 width=64) (actual time=3.981..3.984 rows=1 loops=1)
   ->  Append  (cost=86.96..393.86 rows=398 width=16) (actual time=3.064..3.917 rows=460 loops=1)
         ->  Subquery Scan on "*SELECT* 1"  (cost=86.96..91.96 rows=200 width=16) (actual time=3.063..3.388 rows=455 loops=1)
               ->  HashAggregate  (cost=86.96..89.96 rows=200 width=115) (actual time=3.062..3.309 rows=455 loops=1)
                     Group Key: _materialized_hypertable_2.merchant_id, _materialized_hypertable_2.store_id, _materialized_hypertable_2.bucket
                     Batches: 1  Memory Usage: 1581kB
                     ->  Custom Scan (ChunkAppend) on _materialized_hypertable_2  (cost=0.28..81.27 rows=455 width=45) (actual time=0.041..1.165 rows=455 loops=1)
                           Chunks excluded during startup: 0
                           ->  Index Scan using _hyper_2_15_chunk__materialized_hypertable_2_merchant_id_bucket on _hyper_2_15_chunk  (cost=0.28..23.53 rows=130 width=45) (actual time=0.041..0.244 rows=130 loops=1)
                                 Index Cond: ((merchant_id = 'merchant-1'::text) AND (bucket < COALESCE(_timescaledb_internal.to_timestamp_without_timezone(_timescaledb_internal.cagg_watermark(2)), '-infinity'::timestamp without time zone)))
                           ->  Index Scan using _hyper_2_16_chunk__materialized_hypertable_2_merchant_id_bucket on _hyper_2_16_chunk  (cost=0.29..57.74 rows=325 width=45) (actual time=0.044..0.839 rows=325 loops=1)
                                 Index Cond: ((merchant_id = 'merchant-1'::text) AND (bucket < COALESCE(_timescaledb_internal.to_timestamp_without_timezone(_timescaledb_internal.cagg_watermark(2)), '-infinity'::timestamp without time zone)))
         ->  Subquery Scan on "*SELECT* 2"  (cost=295.46..299.92 rows=198 width=16) (actual time=0.464..0.469 rows=5 loops=1)
               ->  HashAggregate  (cost=295.46..297.94 rows=198 width=115) (actual time=0.463..0.467 rows=5 loops=1)
                     Group Key: transactions.merchant_id, transactions.store_id, time_bucket('1 day'::interval, transactions.transaction_updated_time)
                     Batches: 1  Memory Usage: 40kB
                     ->  Custom Scan (ChunkAppend) on transactions  (cost=0.43..292.99 rows=198 width=31) (actual time=0.041..0.385 rows=112 loops=1)
                           Chunks excluded during startup: 13
                           ->  Index Scan using _hyper_1_14_chunk_transactions_transaction_updated_time_idx on _hyper_1_14_chunk  (cost=0.42..258.04 rows=185 width=31) (actual time=0.039..0.355 rows=112 loops=1)
                                 Index Cond: (transaction_updated_time >= COALESCE(_timescaledb_internal.to_timestamp_without_timezone(_timescaledb_internal.cagg_watermark(2)), '-infinity'::timestamp without time zone))
                                 Filter: (merchant_id = 'merchant-1'::text)
                                 Rows Removed by Filter: 30
 Planning Time: 9.761 ms
 Execution Time: 4.956 ms
(24 rows)
```



# Alter table

```
 exploration=# ALTER TABLE transactions ADD COLUMN fee_10 int NULL;
ALTER TABLE
Time: 29.147 ms


exploration=# DROP MATERIALIZED VIEW transactions_daily;
NOTICE:  drop cascades to 2 other objects
DETAIL:  drop cascades to table _timescaledb_internal._hyper_2_15_chunk
drop cascades to table _timescaledb_internal._hyper_2_16_chunk
DROP MATERIALIZED VIEW
Time: 75.336 ms

exploration=# CREATE MATERIALIZED VIEW transactions_daily
WITH (timescaledb.continuous)
AS
SELECT
   time_bucket('1 day', transaction_updated_time) as bucket,
   merchant_id,
   store_id,

   sum(fee_1) as fee_1,
   sum(fee_2) as fee_2,
   sum(fee_3) as fee_3,
   sum(fee_4) as fee_4,
   sum(fee_5) as fee_5,
   sum(fee_6) as fee_6,
   sum(fee_7) as fee_7,
   sum(fee_8) as fee_8,
   sum(fee_9) as fee_9,
   sum(fee_10) as fee_10,
   sum(total_fee) as total_fee,

   count(*) as transaction_count
FROM
   transactions
GROUP BY merchant_id, store_id, bucket
WITH NO DATA;
CREATE MATERIALIZED VIEW
Time: 88.822 ms


exploration=# CALL refresh_continuous_aggregate('transactions_daily', NULL, NULL);

CALL
Time: 71074.520 ms (01:11.075)
```

# Compare

```
exploration=# select avg(total_fee) from transactions;
         avg
----------------------
 454.5304017000000000
(1 row)
Time: 38492.480 ms (00:38.492)

exploration=# select sum(total_fee)/sum(transaction_count) from transactions_daily;
       ?column?
----------------------
 454.5304017000000000
(1 row)
Time: 169.747 ms

exploration=# select count(*) from transactions;
  count
----------
 10000000
(1 row)
Time: 14364.812 ms (00:14.365)

exploration=# select count(*) from transactions_daily;
 count
-------
  6368
(1 row)
Time: 88.880 ms
```

# Compression

Before 
3 month uncompressed => 10GB

After 
1 month uncompressed + 2 month compressed => 5GB

```
exploration=# SELECT * FROM transactions WHERE transaction_id = '7757fd62-8bfe-11ec-ab4b-63d923f6a2a2' and transaction_updated_time > now() - interval '14 day';

exploration=# SELECT * FROM transactions WHERE transaction_id = '7757fd62-8bfe-11ec-ab4b-63d923f6a2a2';
Time: 513.461 ms

exploration=# SELECT * FROM transactions WHERE transaction_id = '65cb27e0-8bfd-11ec-ab4b-63d923f6a2a2';
Time: 383.735 ms

exploration=# SELECT sum(fee_1) FROM transactions WHERE transaction_updated_time < now() - interval '2 month';
    sum
-----------
 158311810
(1 row)

Time: 877.993 ms
exploration=# SELECT sum(fee_1) FROM transactions WHERE transaction_updated_time > now() - inte
rval '1 month';
    sum
-----------
 172811617
(1 row)

Time: 18492.094 ms (00:18.492)
```


# Analyze visual

psql -U postgres -h localhost -p 5433 -d exploration -qAt -c "EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) SELECT store_id, sum(total_fee) FROM transactions WHERE merchant_id = 'merchant-2' AND transaction_updated_time > NOW() - INTERVAL '1 month' GROUP BY store_id;"

psql -U postgres -h localhost -p 5433 -d exploration -qAt -c "EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) SELECT store_id, sum(total_fee) FROM transactions_daily WHERE merchant_id = 'merchant-2' AND bucket > NOW() - INTERVAL '1 month' GROUP BY store_id;"


http://tatiyants.com/pev/#/plans/new


# Creating new aggregate

30 million data

```
exploration=# CREATE MATERIALIZED VIEW transactions_weekly_avg
WITH (timescaledb.continuous)
AS
SELECT
   time_bucket('7 day', transaction_updated_time) as bucket,
   merchant_id,
   store_id,

   avg(total_fee) as total_fee
FROM
   transactions
GROUP BY merchant_id, store_id, bucket
WITH DATA;
NOTICE:  refreshing continuous aggregate "transactions_weekly_avg"
HINT:  Use WITH NO DATA if you do not want to refresh the continuous aggregate on creation.
CREATE MATERIALIZED VIEW
Time: 261120.502 ms (04:21.121)
```

# Update query

```
exploration=# UPDATE transactions SET transaction_updated_time = now() WHERE transaction_id = 'd7dd00ea-8c43-11ec-ab4b-63d923f6a2a2' AND transaction_updated_time > '2022-02-01';
ERROR:  new row for relation "_hyper_1_16_chunk" violates check constraint "constraint_16"
DETAIL:  Failing row contains (2022-02-13 02:58:32.388652, 2022-02-20 19:02:57.249809, 25200, d7dd00ea-8c43-11ec-ab4b-63d923f6a2a2, d7dd00eb-8c43-11ec-ab4b-63d923f6a2a2, d7dd00ec-8c43-11ec-ab4b-63d923f6a2a2, d7dd00ed-8c43-11ec-ab4b-63d923f6a2a2, d7dd00ee-8c43-11ec-ab4b-63d923f6a2a2, d7dd00ef-8c43-11ec-ab4b-63d923f6a2a2, merchant-1, store-1, 1, 1, 1, 2, 1, 4, 62, 80, 41, 73, 100, 43, 84, 39, 526).
Time: 26.056 ms
```

```sql
BEGIN;

INSERT INTO transactions (transaction_id, alternative_id_1, alternative_id_2, alternative_id_3, alternative_id_4, alternative_id_5, total_fee, transaction_updated_time, transaction_created_time)
      SELECT transaction_id, alternative_id_1, alternative_id_2, alternative_id_3, alternative_id_4, alternative_id_5, total_fee, now(), transaction_created_time
      FROM transactions
      WHERE transaction_id = 'd7dd00e4-8c43-11ec-ab4b-63d923f6a2a2' AND transaction_updated_time = '2022-02-13 02:58:32.129452';

DELETE FROM transactions WHERE transaction_id = 'd7dd00e4-8c43-11ec-ab4b-63d923f6a2a2' AND transaction_updated_time = '2022-02-13 02:58:32.129452';

COMMIT;
```

# vs MySQL

Insert time ~1 hour

```
mysql> select count(*) from transactions;
+----------+
| count(*) |
+----------+
| 10000001 |
+----------+
1 row in set (45.94 sec)
```

```
mysql> SELECT sum(total_fee), count(*) from transactions WHERE merchant_id = 'merchant-1';
+----------------+----------+
| sum(total_fee) | count(*) |
+----------------+----------+
|     3635652669 |  7998871 |
+----------------+----------+
1 row in set (6 min 52.35 sec)
```

Explain analyze

```
-> Aggregate: sum(transactions.total_fee), count(0)  (cost=1566764.00 rows=4902925) (actual time=457808.339..457808.340 rows=1 loops=1)
    -> Index lookup on transactions using i6 (merchant_id='merchant-1')  (cost=1076471.50 rows=4902925) (actual time=86.929..456590.123 rows=7998871 loops=1)
```

# Misc

All of this is running on 70 USD "server", running CPU from 2008

https://www.cpubenchmark.net/compare/Intel-Xeon-E5-2676-v3-vs-Intel-Core2-Duo-E8400/2643vs955

![selfhosted-server-image](img/test-server.jpg)