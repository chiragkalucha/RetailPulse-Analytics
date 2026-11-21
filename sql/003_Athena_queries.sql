-- ============================================================
-- RetailPulse | Athena setup and validation
-- Engine: Amazon Athena (Asia Pacific, Sydney)
-- Source: s3://retailpulsechirag-700002442408-ap-southeast-2-an/processed/
-- Run order: 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7
-- ============================================================


-- ------------------------------------------------------------
-- 1. SETUP: create the database (a named folder for tables)
-- ------------------------------------------------------------
CREATE DATABASE retail_pulse;


-- ------------------------------------------------------------
-- 2. SETUP: define the table over the Parquet files in S3
--    EXTERNAL = only a definition; dropping it never deletes S3 data.
--    Column names must match the Parquet file (customer_id, not "Customer ID"),
--    otherwise the column silently returns NULLs.
--    Keep only Parquet files with this schema under processed/.
-- ------------------------------------------------------------
CREATE EXTERNAL TABLE retail_pulse.retail_clean (
  invoice         string,
  stockcode       string,
  description     string,
  quantity        bigint,
  invoicedate     timestamp,
  price           double,
  customer_id     bigint,
  country         string,
  is_non_product  boolean
)
STORED AS PARQUET
LOCATION 's3://retailpulsechirag-700002442408-ap-southeast-2-an/processed/';


-- ------------------------------------------------------------
-- 3. CHECK: row count
--    Expected: 1,026,833 (matches the row count printed by clean_to_parquet.py)
-- ------------------------------------------------------------
SELECT COUNT(*) FROM retail_pulse.retail_clean;


-- ------------------------------------------------------------
-- 4. CHECK: preview rows
--    Look for columns that are entirely empty (sign of a name mismatch).
--    SELECT * reads every column, so it scans the most data.
-- ------------------------------------------------------------
SELECT * FROM retail_pulse.retail_clean LIMIT 100;


-- ------------------------------------------------------------
-- 5. CHECK: customer_id null test
--    rows_with_customer = 0 means the column names do not match the file.
--    Lower than rows_total is normal: guest orders have no customer ID.
--    Last run: 797,832 of 1,026,833.
-- ------------------------------------------------------------
SELECT COUNT(*) AS rows_total, COUNT(customer_id) AS rows_with_customer
FROM retail_pulse.retail_clean;


-- ------------------------------------------------------------
-- 6. VALIDATION: revenue by country vs Postgres (Phase 2)
--    Restricted to Postgres's date range (up to 2010-12-09) so the
--    comparison covers the same period. Top 5 matched Postgres
--    (UK differs by 0.01: double in Athena vs numeric(10,2) in Postgres).
-- ------------------------------------------------------------
SELECT country,
       CAST(ROUND(SUM(quantity * price), 2) AS DECIMAL(18,2)) AS revenue
FROM retail_pulse.retail_clean
WHERE is_non_product = false
  AND invoice NOT LIKE 'C%'
  AND invoicedate < TIMESTAMP '2010-12-10 00:00:00'
GROUP BY country
ORDER BY revenue DESC
LIMIT 5;


-- ------------------------------------------------------------
-- 7. CHECK: date coverage of the table
--    Result: 2009-12-01 to 2011-12-09 (two years, both Excel sheets).
--    Postgres covers only the first year.
-- ------------------------------------------------------------
SELECT MIN(invoicedate) AS first_day, MAX(invoicedate) AS last_day
FROM retail_pulse.retail_clean;
