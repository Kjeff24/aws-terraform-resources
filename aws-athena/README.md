# AWS Athena Analytics with Glue ETL

A comprehensive Terraform module for setting up an end-to-end data analytics pipeline using AWS Glue ETL and Athena. This integrated solution automatically processes raw data, transforms it to optimized formats, and enables interactive SQL queries. The project provisions S3 buckets, Glue Crawler, Glue ETL Jobs, Glue Workflows, Glue Data Catalog, Athena workgroups, and IAM roles with proper permissions.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Modules](#modules)
- [Example Queries](#example-queries)
- [Outputs](#outputs)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This Terraform module provisions a complete end-to-end data analytics pipeline that enables you to:

- **Process raw data** automatically using AWS Glue Crawler and ETL Jobs
- **Transform data** to optimized formats (Parquet recommended for Athena)
- **Discover schemas** automatically with Glue Crawler
- **Query processed data** using standard SQL with Athena
- **Orchestrate pipelines** with Glue Workflows
- **Organize metadata** using AWS Glue Data Catalog
- **Manage query execution** with configurable Athena workgroups
- **Control access** with IAM roles and policies
- **Store results** in dedicated S3 buckets

## 🏗️ Architecture

```
┌─────────────────┐
│  S3 Raw Data    │  Raw data files (CSV, JSON, etc.)
│     Bucket      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Glue Crawler    │  Discovers raw data schema
│     (Raw)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Glue ETL Job   │  Transforms data to Parquet/JSON
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ S3 Processed    │  Optimized data (Parquet recommended)
│    Data Bucket  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Glue Crawler    │  Auto-discovers processed data schema
│  (Processed)    │  Creates tables automatically!
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Glue Data       │  Metadata catalog (databases, tables)
│    Catalog      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│    Athena       │  SQL query engine
│  Workgroups     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Query Results   │  Query results stored here
│     S3 Bucket   │
└─────────────────┘
```

### Pipeline Flow

1. **Raw Data Ingestion**: Upload raw data files (CSV, JSON, etc.) to the raw data S3 bucket (or place in `files/` directory)
2. **Schema Discovery (Raw)**: Glue Crawler automatically discovers and catalogs the raw data schema
3. **Data Transformation**: Glue ETL Job transforms data to optimized format (Parquet recommended)
4. **Data Storage**: Processed data is stored in the processed data bucket
5. **Schema Discovery (Processed)**: Glue Crawler automatically discovers and catalogs the processed data schema (creates tables automatically!)
6. **Query Execution**: Athena queries the processed data using automatically discovered tables
7. **Results Storage**: Query results are stored in the query results bucket

## ✨ Features

### Core Features
- ✅ **Integrated Pipeline**: Complete ETL + Analytics solution
- ✅ **S3 Storage**: Separate buckets for raw data, processed data, and query results
- ✅ **Glue Crawler**: Automatic schema discovery and cataloging
- ✅ **Glue ETL Jobs**: Transform data to optimized formats (Parquet, JSON, etc.)
- ✅ **Glue Workflows**: Automated pipeline orchestration (Crawler → ETL Job)
- ✅ **Glue Data Catalog**: Database and table definitions for metadata
- ✅ **Athena Workgroups**: Configurable workgroups with encryption and result location
- ✅ **IAM Integration**: Roles and policies for secure access (Glue + Athena)
- ✅ **Encryption**: Server-side encryption (SSE-S3 or SSE-KMS)
- ✅ **Versioning**: Optional S3 bucket versioning

### Advanced Features
- ✅ **Data Quality Checks**: Built-in quality validation and reporting
- ✅ **Time-based Partitioning**: Automatic partitioning by year/month/day
- ✅ **Multiple Workgroups**: Create multiple workgroups for different teams/use cases
- ✅ **Custom Encryption**: KMS encryption for query results
- ✅ **CloudWatch Metrics**: Optional metrics publishing
- ✅ **Engine Version Control**: Specify Athena engine version
- ✅ **Partitioned Tables**: Support for partitioned data
- ✅ **Job Bookmarks**: Incremental processing support
- ✅ **Spark UI**: Built-in Spark UI for debugging

## 📦 Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create:
  - S3 buckets
  - IAM roles and policies
  - Glue databases, tables, crawlers, jobs, and workflows
  - Athena workgroups
- **Raw data files** to upload (CSV, JSON, etc.) - will be processed by Glue ETL

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
cd aws-athena
```

### 2. Configure Backend

Edit `backend.tf` to configure your Terraform backend:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "athena/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

### 3. Configure Variables

Create a `terraform.tfvars` file:

```hcl
project_name = "my-athena-analytics"
region       = "eu-west-1"

# Optional: Create example tables
glue_tables = {
  "sales_data" = {
    description = "Sales transaction data"
    location    = "s3://my-athena-analytics-data-xxxxx/sales/"
    columns = [
      { name = "transaction_id", type = "string" },
      { name = "date", type = "date" },
      { name = "amount", type = "double" },
      { name = "product", type = "string" }
    ]
  }
}
```

### 4. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

### 5. Add Raw Data Files (Optional)

You can either:

**Option A: Automatic Upload (Recommended)**
Place your raw data files in the `files/` directory. They will be automatically uploaded to the raw data bucket when you run `terraform apply`:

```bash
# Place your data files in the files/ directory
cp your_data.csv files/
cp your_data.json files/

# Files will be uploaded automatically on terraform apply
```

**Option B: Manual Upload**
Upload files directly to S3 after deployment:

```bash
# Get the raw data bucket name
terraform output raw_data_bucket_name

# Upload raw data
aws s3 cp sales_data.csv s3://$(terraform output -raw raw_data_bucket_name)/sales/
```

### 6. Run Glue ETL Pipeline

Start the Glue workflow to process the raw data:

```bash
# Get the workflow name
WORKFLOW_NAME=$(terraform output -raw glue_workflow_name)

# Start the workflow (this runs: raw crawler → ETL job → processed crawler)
aws glue start-workflow-run --name $WORKFLOW_NAME
```

The workflow automatically:
1. Runs the raw data crawler to discover raw data schema
2. Runs the ETL job to transform data
3. Runs the processed data crawler to automatically create tables for Athena

Or run components individually:

```bash
# Start raw data crawler
RAW_CRAWLER=$(terraform output -raw glue_raw_crawler_name)
aws glue start-crawler --name $RAW_CRAWLER

# After crawler completes, start ETL job
JOB_NAME=$(terraform output -raw glue_job_name)
aws glue start-job-run --job-name $JOB_NAME

# After ETL job completes, start processed data crawler
PROCESSED_CRAWLER=$(terraform output -raw glue_processed_crawler_name)
aws glue start-crawler --name $PROCESSED_CRAWLER
```

### 7. Query with Athena

Once the workflow completes (raw crawler → ETL job → processed crawler), query the automatically discovered tables:

```sql
-- In Athena console, select your workgroup and database
-- Tables are automatically discovered by the processed data crawler
SELECT * FROM processed_sales LIMIT 10;

-- Or query any table that was automatically discovered
SHOW TABLES;
```

## ⚙️ Configuration

### Main Variables

#### General Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Project name for resource naming | `"athena-analytics"` | No |
| `region` | AWS region for deployment | `"eu-west-1"` | No |
| `tags` | Common tags for all resources | `{}` | No |

#### S3 Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_versioning` | Enable S3 bucket versioning | `true` | No |
| `enable_encryption` | Enable server-side encryption | `true` | No |
| `kms_key_id` | KMS key ID for encryption | `null` | No |

#### Glue ETL Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_glue_etl` | Enable Glue ETL pipeline (crawler, job, workflow) | `true` | No |
| `glue_crawler.table_prefix` | Prefix for tables created by crawler | `"raw_"` | No |
| `glue_crawler.schedule` | Crawler schedule (cron/rate). Use null for manual | `null` | No |
| `glue_job_config` | Glue ETL job configuration | See below | No |

Default Glue ETL job configuration:

```hcl
glue_job_config = {
  script_path          = "scripts/glue-etl-job.py"
  input_table_prefix   = "raw_"
  output_path          = "processed/"
  output_format        = "parquet"  # Parquet recommended for Athena
  worker_type          = "G.1X"
  number_of_workers    = 2
  version              = "5.0"
  job_timeout          = 2880
  max_retries          = 1
  max_concurrent_runs  = 1
  enable_quality_checks = true
  quality_report_path   = "quality-reports/"
  bad_data_path         = "bad-data/"
  filter_bad_data       = true
  job_bookmark_option   = "job-bookmark-disable"
  enable_partitioning   = true
  partition_columns     = "year,month,day"
  enable_job_insights   = true
  enable_spark_ui       = true
  job_language          = "python"
  python_version        = "3"
  log_retention_days    = 7
}
```

#### Glue Data Catalog

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `glue_database.name` | Glue database name for processed data | `"athena_database"` | No |
| `glue_database.description` | Database description | `"Database for Athena queries"` | No |
| `glue_tables` | Map of tables to create manually (optional - crawler auto-discovers tables) | `{}` | No |

**Note:** The `glue_tables` variable is optional. When Glue ETL is enabled, a crawler automatically discovers and catalogs processed data tables after the ETL job completes. You only need to define `glue_tables` if you want to manually override table definitions.

#### Athena Workgroups

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `athena_workgroups` | Map of workgroups to create | See below | No |

Default workgroup configuration:

```hcl
athena_workgroups = {
  primary = {
    description              = "Primary Athena workgroup"
    enforce_workgroup_config  = false
    publish_cloudwatch_metrics = true
    result_configuration = {
      output_location = null  # Uses default: s3://query-results-bucket/primary/
      encryption_configuration = {
        encryption_option = "SSE_S3"
        kms_key           = null
      }
    }
    state = "ENABLED"
  }
}
```

## 📖 Usage

### Basic Usage (With Glue ETL)

1. **Add Raw Data**: Place your raw data files (CSV, JSON, etc.) in the `files/` directory
2. **Deploy Infrastructure**: Run `terraform apply` (files are uploaded automatically)
3. **Run Glue Workflow**: Start the Glue workflow to process data (Crawler → ETL Job)
4. **Query Processed Data**: Use Athena to query the processed data (Parquet format)

### Basic Usage (Without Glue ETL)

If you disable Glue ETL (`enable_glue_etl = false`):

1. **Deploy Infrastructure**: Run `terraform apply`
2. **Upload Processed Data**: Place your processed data files (Parquet, JSON, etc.) in the processed data bucket
3. **Create Tables**: Either use the `glue_tables` variable or create tables manually
4. **Query Data**: Use Athena console, CLI, or SDK to run SQL queries

### Creating Tables

#### Option 1: Using Terraform Variables

Define tables in `terraform.tfvars`:

```hcl
glue_tables = {
  "customers" = {
    description = "Customer data table"
    location    = "s3://my-athena-analytics-data-xxxxx/customers/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    serde_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
    columns = [
      { name = "customer_id", type = "bigint" },
      { name = "name", type = "string" },
      { name = "email", type = "string" },
      { name = "created_at", type = "timestamp" }
    ]
  }
}
```

#### Option 2: Using AWS Glue Console

1. Navigate to AWS Glue Console
2. Select your database
3. Create table manually or use a crawler

#### Option 3: Using CREATE TABLE Statement in Athena

```sql
CREATE EXTERNAL TABLE customers (
  customer_id bigint,
  name string,
  email string,
  created_at timestamp
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe'
WITH SERDEPROPERTIES (
  'serialization.format' = ',',
  'field.delim' = ','
)
STORED AS INPUTFORMAT 'org.apache.hadoop.mapred.TextInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://my-athena-analytics-data-xxxxx/customers/'
TBLPROPERTIES ('has_encrypted_data'='false');
```

### Running Queries

#### Using AWS Console

1. Navigate to Athena console
2. Select your workgroup
3. Select your database
4. Write and execute SQL queries

#### Using AWS CLI

```bash
# Start a query execution
aws athena start-query-execution \
  --query-string "SELECT * FROM customers LIMIT 10" \
  --work-group primary \
  --result-configuration OutputLocation=s3://my-athena-analytics-query-results-xxxxx/

# Get query results
aws athena get-query-results \
  --query-execution-id <execution-id>
```

#### Using boto3 (Python)

```python
import boto3

athena = boto3.client('athena')

response = athena.start_query_execution(
    QueryString='SELECT * FROM customers LIMIT 10',
    WorkGroup='primary',
    ResultConfiguration={
        'OutputLocation': 's3://my-athena-analytics-query-results-xxxxx/'
    }
)

query_execution_id = response['QueryExecutionId']
```

## 🧩 Modules

### S3 Module (`modules/s3`)
- Creates raw data bucket (input for Glue ETL)
- Creates processed data bucket (output from Glue ETL, input for Athena)
- Creates query results bucket (Athena query results)
- Configurable versioning and encryption
- Public access blocking
- **Automatically uploads files** from `files/` directory to raw data bucket
- Uploads Glue ETL scripts automatically

### Glue Database Module (`modules/glue-database`)
- Creates Glue database for raw data
- Used by Glue Crawler and ETL Job

### Glue Crawler Module (`modules/glue-crawler`)
- Discovers data schema automatically
- Creates tables in Glue Catalog
- Supports both raw data and processed data crawling
- Configurable schedule or on-demand
- Supports multiple data formats (CSV, JSON, Parquet, etc.)

### Glue Job Module (`modules/glue-job`)
- Creates ETL job with PySpark/Spark script
- Transforms data to optimized formats
- Configurable workers, timeout, retries
- Supports data quality checks and partitioning

### Glue Workflow Module (`modules/glue-workflow`)
- Orchestrates complete ETL pipeline
- Triggers raw data crawler on-demand
- Triggers ETL job after raw crawler succeeds
- Triggers processed data crawler after ETL job succeeds
- Fully automated: no manual table definitions needed!

### Glue Data Catalog Module (`modules/glue-catalog`)
- Creates Glue database for processed data
- Creates Glue tables with schemas (optional)
- Supports partitioned tables
- Configurable storage formats

### Athena Module (`modules/athena`)
- Creates Athena workgroups
- Configures result locations
- Sets encryption options
- Manages engine versions

### IAM Module (`modules/iam`)
- Creates Glue service role with S3, Glue, and CloudWatch permissions
- Creates Athena user role (optional)
- Grants S3 read/write permissions
- Grants Glue Catalog permissions
- Grants Athena query permissions

### Basic SELECT Query

```sql
SELECT * FROM customers LIMIT 10;
```

### Aggregation Query

```sql
SELECT 
  DATE_TRUNC('month', created_at) as month,
  COUNT(*) as customer_count
FROM customers
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;
```

### JOIN Query

```sql
SELECT 
  c.customer_id,
  c.name,
  SUM(s.amount) as total_spent
FROM customers c
JOIN sales s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC
LIMIT 10;
```

### Partitioned Table Query

```sql
SELECT * FROM sales_data
WHERE year = 2024 AND month = 1
LIMIT 100;
```

## 📤 Outputs

After applying, you can access:

```hcl
# S3 Buckets
output.data_bucket_name
output.query_results_bucket_name

# Glue Catalog
output.glue_database_name
output.glue_table_names

# Athena Workgroups
output.athena_workgroup_names

# IAM
output.athena_user_role_arn
```

## 🐛 Troubleshooting

### Common Issues

#### Query Fails with "Access Denied"
- Check IAM role has `s3:GetObject` and `s3:ListBucket` permissions on data bucket
- Verify IAM role has `s3:PutObject` permission on query results bucket
- Ensure IAM role has `glue:GetTable` and `glue:GetDatabase` permissions

#### "Table Not Found" Error
- Verify table exists in Glue Data Catalog
- Check table location points to correct S3 path
- Ensure data files are in the location specified in table definition

#### Query Results Not Appearing
- Check query results bucket permissions
- Verify workgroup result location is correct
- Check CloudWatch logs for errors

#### High Query Costs
- Use columnar formats (Parquet) instead of CSV
- Partition large datasets
- Use appropriate workgroups with result size limits
- Enable query result caching

### Debugging

1. **Check CloudWatch Logs**:
   ```bash
   aws logs tail /aws-athena/primary --follow
   ```

2. **Verify S3 Permissions**:
   ```bash
   aws s3 ls s3://<data-bucket-name>/
   aws s3 ls s3://<query-results-bucket-name>/
   ```

3. **Test IAM Permissions**:
   ```bash
   aws iam simulate-principal-policy \
     --policy-source-arn <role-arn> \
     --action-names s3:GetObject \
     --resource-arns arn:aws:s3:::bucket-name/*
   ```

## 📚 Additional Resources

- [AWS Athena Documentation](https://docs.aws.amazon.com/athena/)
- [AWS Glue Data Catalog Documentation](https://docs.aws.amazon.com/glue/latest/dg/catalog-and-crawler.html)
- [Athena Best Practices](https://docs.aws.amazon.com/athena/latest/ug/best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📄 License

This project is provided as-is for educational and production use.

## 🤝 Contributing

Contributions are welcome! Please ensure:
- Code follows existing patterns
- All tests pass
- Documentation is updated

---

**Note**: This module creates AWS resources that may incur costs. Always review and understand the resources being created before applying. Athena charges based on data scanned per query.
