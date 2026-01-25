# Glue ETL Job Script - Function Documentation

This document describes all functions and key components in the `glue-etl-job.py` script.

## 📋 Table of Contents

- [Overview](#overview)
- [Constants](#constants)
- [Main Functions](#main-functions)
- [Execution Flow](#execution-flow)
- [Error Handling](#error-handling)

## 🎯 Overview

The `glue-etl-job.py` script is a PySpark-based AWS Glue ETL job that:
- Reads data from AWS Glue Data Catalog tables
- Performs data quality checks
- Transforms data to various output formats (JSON, Parquet, CSV, ORC)
- Partitions data by processing time
- Writes quality reports and handles bad data

## 📦 Constants

### `PARTITION_COLUMN_MAP`

**Location:** Lines 15-21

**Purpose:** Maps partition column names to Spark SQL functions for extracting time components.

**Structure:**
```python
PARTITION_COLUMN_MAP = {
    "year": lambda ts: F.year(ts),
    "month": lambda ts: F.month(ts),
    "day": lambda ts: F.dayofmonth(ts),
    "hour": lambda ts: F.hour(ts),
    "minute": lambda ts: F.minute(ts),
}
```

**Usage:** Used by `add_partition_columns()` to dynamically add time-based partition columns to DataFrames.

**Supported Columns:**
- `year` - Extracts year from timestamp
- `month` - Extracts month (1-12) from timestamp
- `day` - Extracts day of month (1-31) from timestamp
- `hour` - Extracts hour (0-23) from timestamp
- `minute` - Extracts minute (0-59) from timestamp

---

## 🔧 Main Functions

### `add_partition_columns(df, partition_cols)`

**Location:** Lines 88-109

**Purpose:** Adds processing time partition columns to a Spark DataFrame.

**Parameters:**
- `df` (DataFrame): The input Spark DataFrame
- `partition_cols` (list): List of partition column names (e.g., `["year", "month", "day"]`)

**Returns:**
- `DataFrame`: DataFrame with partition columns added

**How it works:**
1. Returns the original DataFrame if `partition_cols` is empty
2. Creates a processing timestamp using `F.current_timestamp()`
3. Iterates through requested partition columns
4. For each valid column name, adds a new column using the corresponding function from `PARTITION_COLUMN_MAP`
5. Warns and skips unknown partition column names

**Example:**
```python
# Input DataFrame: customer_id, product_name, sales
# Output DataFrame: customer_id, product_name, sales, year, month, day
df_partitioned = add_partition_columns(df, ["year", "month", "day"])
```

**Use Case:** Enables time-based partitioning for efficient querying in Athena and data organization in S3.

---

### `perform_quality_checks(df, table_name)`

**Location:** Lines 111-179

**Purpose:** Performs comprehensive data quality checks on a DataFrame and calculates quality metrics.

**Parameters:**
- `df` (DataFrame): The input Spark DataFrame to check
- `table_name` (string): Name of the table being checked (for reporting)

**Returns:**
- `tuple`: `(metrics_dict, df)` where:
  - `metrics_dict`: Dictionary containing quality metrics
  - `df`: The original DataFrame (unchanged)

**Metrics Calculated:**

1. **Table-level Metrics:**
   - `total_records`: Total number of records
   - `duplicates`: Number of duplicate records
   - `null_records`: Number of records with any null values
   - `quality_score`: Overall quality score (0-100)

2. **Column-level Metrics** (per column):
   - `column_name`: Name of the column
   - `data_type`: Spark data type
   - `null_count`: Number of null values
   - `null_percentage`: Percentage of null values
   - `distinct_count`: Number of distinct values
   - `empty_string_count`: Number of empty strings (string columns only)

**Quality Score Calculation:**
- Base score: 100
- Null penalty: `(null_records / total_records) * 50`
- Duplicate penalty: `(duplicates / total_records) * 30`
- Empty string penalty: `(empty_strings / total_records) * 20`
- Final score: `max(0, 100 - null_penalty - duplicate_penalty - empty_penalty)`

**Example Output:**
```python
{
    "table_name": "raw_sales",
    "timestamp": "2024-01-25T16:06:01",
    "total_records": 18,
    "duplicates": 0,
    "null_records": 0,
    "quality_score": 100.0,
    "columns": [
        {
            "column_name": "customer_id",
            "data_type": "IntegerType",
            "null_count": 0,
            "null_percentage": 0.0,
            "distinct_count": 6,
            "empty_string_count": 0
        },
        ...
    ]
}
```

**Use Case:** Provides data quality insights before transformation, helps identify data issues, and generates quality reports.

---

### `write_quality_report(metrics, output_bucket, report_path, table_name, job_run_short)`

**Location:** Lines 181-205

**Purpose:** Writes quality metrics as a JSON report to S3.

**Parameters:**
- `metrics` (dict): Quality metrics dictionary from `perform_quality_checks()`
- `output_bucket` (string): S3 bucket name for output
- `report_path` (string): S3 path prefix for reports (e.g., `"quality-reports/"`)
- `table_name` (string): Name of the table (used in filename)
- `job_run_short` (string): Short job run ID (used in filename for uniqueness)

**Returns:**
- `string` or `None`: S3 key of the written report, or `None` if writing failed

**File Naming:**
- Format: `{report_path}/{table_name}_{job_run_short}.json`
- Example: `quality-reports/raw_sales_4cb48fbd74df386c.json`

**Features:**
- Uses job run ID to ensure one report per job run per table
- Retries of the same job run will overwrite the previous report
- Handles errors gracefully (returns `None` on failure, prints warning)

**Example:**
```python
report_key = write_quality_report(
    quality_metrics,
    "my-bucket",
    "quality-reports/",
    "raw_sales",
    "4cb48fbd74df386c"
)
# Returns: "quality-reports/raw_sales_4cb48fbd74df386c.json"
```

**Use Case:** Persists quality metrics for historical tracking, monitoring, and analysis.

---

## 🔄 Execution Flow

### 1. Initialization (Lines 23-81)

**What happens:**
- Parses job arguments from Terraform configuration
- Extracts `JOB_RUN_ID` from `sys.argv` (reserved argument)
- Initializes SparkContext and GlueContext
- Validates output format
- Parses configuration flags

**Key Variables Set:**
- `input_db`: Glue Catalog database name
- `prefix`: Table name prefix to match
- `output_bucket`: S3 bucket for output
- `output_format`: Target format (json, parquet, csv, orc)
- `enable_quality_checks`: Boolean flag
- `enable_partitioning`: Boolean flag
- `partition_columns`: List of partition column names

---

### 2. Table Discovery (Lines 213-253)

**What happens:**
- Connects to AWS Glue service
- Retrieves all tables from the specified database
- Filters tables by prefix (e.g., `"raw_"`)
- Handles pagination with `NextToken`
- Collects matching table names

**Output:**
- `matching_tables`: List of table names to process

**Error Handling:**
- Catches `ClientError` and prints detailed error information
- Raises exception on failure to stop job

---

### 3. Table Processing Loop (Lines 257-397)

For each matching table:

#### 3.1 Data Reading (Lines 263-277)
- Reads from Glue Data Catalog using DynamicFrame API
- Converts DynamicFrame to Spark DataFrame
- Counts records
- Skips empty tables

#### 3.2 Quality Checks (Lines 284-351)
- Calls `perform_quality_checks()` if enabled
- Prints quality metrics to console
- Optionally filters bad data (duplicates, nulls)
- Writes bad data to separate S3 location if filtering enabled
- Writes quality report to S3

#### 3.3 Data Transformation (Lines 353-384)
- Adds partition columns if partitioning enabled
- Writes clean data to S3 in specified format
- Uses appropriate write mode (append for partitioning, overwrite otherwise)
- Applies partitioning if enabled

#### 3.4 Error Handling (Lines 387-397)
- Catches exceptions per table
- Logs error with full traceback
- Continues processing other tables
- Tracks failed tables for summary

---

### 4. Summary and Cleanup (Lines 399-439)

**What happens:**
- Prints job summary (tables found, processed, failed)
- Lists quality report locations
- Raises exception if any tables failed (with details)
- Commits job bookmark in `finally` block

**Summary Output:**
```
============================================================
JOB SUMMARY
============================================================
Total tables found: 1
Successfully processed: 1
Failed: 0

Quality reports generated: 1
  - s3://bucket/quality-reports/table_jobrunid.json
============================================================
```

---

## 🛡️ Error Handling

### Per-Table Error Handling

**Location:** Lines 387-397

**Strategy:**
- Each table is processed in a try-except block
- Errors are caught, logged with traceback, and stored
- Processing continues for remaining tables
- Failed tables are reported in the summary

**Error Information Captured:**
- Table name
- Error message
- Full stack trace

### Global Error Handling

**Location:** Lines 429-433

**Strategy:**
- Outer try-except catches fatal errors (e.g., table discovery failures)
- Prints formatted error message
- Re-raises exception to fail the job

### Job Bookmark Commit

**Location:** Lines 435-439

**Strategy:**
- Always executes in `finally` block
- Safe to call even if bookmarks are disabled
- Required for bookmark functionality when enabled

---

## 📊 Data Flow Diagram

```
┌─────────────────┐
│  Glue Catalog   │
│     Tables      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  DynamicFrame   │  (Glue API)
│   from_catalog  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Spark          │
│  DataFrame      │
└────────┬────────┘
         │
         ├─────────────────┐
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ Quality Checks  │  │ Add Partitions  │
│ (if enabled)    │  │ (if enabled)    │
└────────┬────────┘  └────────┬────────┘
         │                    │
         ├───────────────────┤
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ Bad Data        │  │ Clean Data      │
│ (if filtered)   │  │ (main output)   │
└────────┬────────┘  └────────┬────────┘
         │                    │
         ▼                    ▼
┌─────────────────┐  ┌─────────────────┐
│ S3 Bad Data     │  │ S3 Output       │
│ Path            │  │ (Partitioned)   │
└─────────────────┘  └─────────────────┘
```

---

## 🔑 Key Concepts

### Job Bookmarks

**Purpose:** Track processed data for incremental processing

**How it works:**
- Uses `transformation_ctx` in DynamicFrame reads
- Commits bookmark state with `job.commit()`
- AWS Glue automatically tracks state when enabled

**In this script:**
- `transformation_ctx=f"dyf_{table_name}"` - Unique context per table
- `job.commit()` - Commits state at end of job

### Partitioning

**Purpose:** Organize data by time for efficient querying

**How it works:**
- Adds partition columns (year, month, day, etc.) based on processing time
- Uses Spark's `partitionBy()` to create Hive-style partitions
- Results in S3 structure: `year=2024/month=1/day=25/`

**Benefits:**
- Partition pruning in Athena (only scans relevant partitions)
- Better organization and data lifecycle management
- No overwrites (each run creates new partition)

### Quality Checks

**Purpose:** Validate data before transformation

**Checks performed:**
1. Duplicate detection (all columns)
2. Null value detection (per column and per record)
3. Empty string detection (string columns)
4. Distinct value counting

**Quality Score:**
- 0-100 scale
- Penalizes nulls (50%), duplicates (30%), empty strings (20%)
- Higher score = better quality

---

## 📝 Function Dependencies

```
main execution
    │
    ├──> perform_quality_checks()
    │       └──> (uses Spark SQL functions)
    │
    ├──> write_quality_report()
    │       └──> (uses boto3 S3 client)
    │
    ├──> add_partition_columns()
    │       └──> (uses PARTITION_COLUMN_MAP)
    │
    └──> DataFrame operations
            ├──> dropDuplicates()
            ├──> dropna()
            ├──> subtract()
            └──> write operations
```

---

## 🎯 Best Practices

1. **Error Handling:** Always wrap table processing in try-except to continue on failures
2. **Logging:** Print progress and metrics for debugging
3. **Partitioning:** Use append mode when partitioning to preserve history
4. **Quality Checks:** Enable for production to catch data issues early
5. **Job Bookmarks:** Use unique `transformation_ctx` per data source
6. **Resource Management:** Let Spark handle DataFrame lifecycle

---

## 🔍 Debugging Tips

1. **Check Logs:** All print statements go to CloudWatch logs
2. **Spark UI:** Enable `enable_spark_ui` to view Spark execution details
3. **Quality Reports:** Review JSON reports in S3 for data issues
4. **Error Messages:** Full tracebacks are printed and included in exception messages
5. **Job Run ID:** Use job run ID to correlate logs and reports

---

## 📚 Related Documentation

- [AWS Glue DynamicFrame API](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-crawler-pyspark-extensions-dynamic-frame.html)
- [PySpark DataFrame API](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/dataframe.html)
- [AWS Glue Job Bookmarks](https://docs.aws.amazon.com/glue/latest/dg/monitor-continuations.html)
