\set ON_ERROR_STOP on

----------------------------------------
-- Hypertable to transactions data
----------------------------------------

DROP database IF EXISTS exploration WITH (FORCE);
CREATE database exploration;
\c exploration
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Step 1: Define regular table
CREATE TABLE IF NOT EXISTS transactions (
   transaction_created_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   transaction_updated_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
   timezone_shift int NULL,

   transaction_id text NULL,
   alternative_id_1 text NULL,
   alternative_id_2 text NULL,
   alternative_id_3 text NULL,
   alternative_id_4 text NULL,
   alternative_id_5 text NULL,

   merchant_id text NULL,
   store_id text NULL,

   category_1 int NULL,
   category_2 int NULL,
   category_3 int NULL,
   category_4 int NULL,
   category_5 int NULL,

   fee_1 int NULL,
   fee_2 int NULL,
   fee_3 int NULL,
   fee_4 int NULL,
   fee_5 int NULL,
   fee_6 int NULL,
   fee_7 int NULL,
   fee_8 int NULL,
   fee_9 int NULL,
   total_fee int NULL,

   PRIMARY KEY (transaction_updated_time, transaction_id)
);

CREATE INDEX ON transactions USING HASH (transaction_id);
CREATE INDEX ON transactions (merchant_id, store_id, category_1, category_2, category_3, category_4, category_5, transaction_updated_time DESC);
CREATE INDEX ON transactions USING HASH (alternative_id_1);
CREATE INDEX ON transactions USING HASH (alternative_id_2);
CREATE INDEX ON transactions USING HASH (alternative_id_3);
CREATE INDEX ON transactions USING HASH (alternative_id_4);
CREATE INDEX ON transactions (alternative_id_5, transaction_updated_time DESC);
CREATE INDEX ON transactions (merchant_id, store_id, alternative_id_1, transaction_updated_time DESC);
CREATE INDEX ON transactions (merchant_id, store_id, alternative_id_2, transaction_updated_time DESC);


-- Step 2: Turn into hypertable
SELECT create_hypertable('transactions','transaction_updated_time', chunk_time_interval => INTERVAL '7 day');


-- Step 3: Various policy for time-series data management

-- Compression
ALTER TABLE transactions SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'merchant_id, store_id',
  timescaledb.compress_orderby = 'transaction_id, transaction_updated_time DESC'
);
SELECT add_compression_policy('transactions', INTERVAL '3 month');
-- To compress manually
-- SELECT compress_chunk(i) from show_chunks('transactions', older_than => INTERVAL '1 month') i;

-- Data retention length
SELECT add_retention_policy('transactions', INTERVAL '1 year');

-- Step 3: Create continuous aggregates
CREATE MATERIALIZED VIEW transactions_daily
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
   sum(total_fee) as total_fee,

   count(*) as transaction_count
FROM
   transactions
GROUP BY merchant_id, store_id, bucket
WITH NO DATA;

SELECT add_continuous_aggregate_policy('transactions_daily',
     start_offset => INTERVAL '1 year',
     end_offset => INTERVAL '30 m',
     schedule_interval => INTERVAL '30 m');