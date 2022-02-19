DROP DATABASE IF EXISTS exploration;
CREATE DATABASE exploration;
USE exploration;

SET GLOBAL local_infile=1;

-- Step 1: Define table
CREATE TABLE IF NOT EXISTS transactions (
   transaction_created_time DATETIME NOT NULL,
   transaction_updated_time DATETIME NOT NULL,
   timezone_shift int NULL,

   transaction_id varchar(32) NOT NULL,
   alternative_id_1 varchar(32) NULL,
   alternative_id_2 varchar(32) NULL,
   alternative_id_3 varchar(32) NULL,
   alternative_id_4 varchar(32) NULL,
   alternative_id_5 varchar(32) NULL,

   merchant_id varchar(32) NULL,
   store_id varchar(32) NULL,

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
) PARTITION BY RANGE(TO_DAYS(transaction_updated_time))(
PARTITION p2021DEC VALUES LESS THAN (TO_DAYS('2022-01-01')),
PARTITION p2022JAN VALUES LESS THAN (TO_DAYS('2022-02-01')),
PARTITION p2022FEB VALUES LESS THAN (TO_DAYS('2022-03-01')),
PARTITION p2022MAR VALUES LESS THAN (TO_DAYS('2022-04-01'))
);

CREATE INDEX i1 USING HASH ON transactions (transaction_id);
CREATE INDEX i2 USING HASH ON transactions (alternative_id_1);
CREATE INDEX i3 USING HASH ON transactions (alternative_id_2);
CREATE INDEX i4 USING HASH ON transactions (alternative_id_3);
CREATE INDEX i5 USING HASH ON transactions (alternative_id_4);
CREATE INDEX i6 ON transactions (merchant_id, store_id, category_1, category_2, category_3, category_4, category_5, transaction_updated_time DESC);
CREATE INDEX i7 ON transactions (alternative_id_5, transaction_updated_time DESC);
CREATE INDEX i8 ON transactions (merchant_id, store_id, alternative_id_1, transaction_updated_time DESC);
CREATE INDEX i9 ON transactions (merchant_id, store_id, alternative_id_2, transaction_updated_time DESC);