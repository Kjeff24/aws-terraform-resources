# AWS Glue ETL Pipeline

A comprehensive Terraform module for building an automated AWS Glue ETL pipeline that transforms data from various formats (CSV, JSON, Parquet, ORC) to different output formats with data quality checks, partitioning, and optional Lake Formation integration.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Usage](#usage)
- [Modules](#modules)
- [Outputs](#outputs)
- [Data Quality](#data-quality)
- [Lake Formation](#lake-formation)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This Terraform module provisions a complete AWS Glue ETL pipeline infrastructure that:

- **Ingests** raw data files (CSV, JSON, etc.) from S3
- **Discovers** data schema using AWS Glue Crawler
- **Transforms** data to various formats (JSON, Parquet, CSV, ORC)
- **Validates** data quality with comprehensive checks
- **Partitions** output data by processing time for efficient querying
- **Orchestrates** the entire pipeline using AWS Glue Workflows

## 🏗️ Architecture

```
┌─────────────┐
│   S3 Raw    │  Raw data files (CSV, JSON, etc.)
│   Bucket    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Glue      │  Discovers schema and creates tables
│   Crawler   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Glue      │  Transforms data with quality checks
│   ETL Job   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  S3 Processed│  Partitioned output (year/month/day)
│    Bucket   │
└─────────────┘
```

## ✨ Features

### Core Features
- ✅ **Multi-format Support**: Convert between CSV, JSON, Parquet, and ORC formats
- ✅ **Data Quality Checks**: Automatic quality scoring, duplicate detection, null validation
- ✅ **Time-based Partitioning**: Automatic partitioning by year/month/day for efficient Athena queries
- ✅ **Bad Data Handling**: Separate storage for filtered bad data with configurable filtering
- ✅ **Quality Reports**: JSON reports with detailed metrics per job run
- ✅ **Workflow Automation**: Automated pipeline execution (Crawler → Job)
- ✅ **Job Bookmarks**: Support for incremental processing
- ✅ **Multi-language Support**: Python (PySpark) and Scala (Spark) scripts

### Advanced Features
- ✅ **Lake Formation Integration**: Optional fine-grained access control
- ✅ **S3 Versioning**: Configurable bucket versioning
- ✅ **Spark UI**: Built-in Spark UI for debugging
- ✅ **Job Insights**: AWS Glue job insights for monitoring
- ✅ **Error Handling**: Comprehensive error tracking and reporting
- ✅ **Retry Logic**: Configurable job retries

## 📦 Prerequisites

- **Terraform** >= 1.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create:
  - S3 buckets
  - IAM roles and policies
  - Glue databases, crawlers, jobs, and workflows
  - (Optional) Lake Formation resources
- **Python 3.x** (for local script development)

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
cd aws-glue-etl-pipeline
```

### 2. Configure Backend

Edit `backend.tf` to configure your Terraform backend:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "glue-etl-pipeline/terraform.tfstate"
    region = "eu-west-1"
  }
}
```

### 3. Configure Variables

Create a `terraform.tfvars` file or modify `variables.tf` defaults:

```hcl
project_name = "my-glue-etl"
region       = "eu-west-1"

glue_job = {
  script_path          = "scripts/glue-etl-job.py"
  input_table_prefix   = "raw_"
  output_path          = "output/"
  output_format        = "json"
  worker_type          = "G.1X"
  number_of_workers    = 2
  version              = "5.0"
  job_timeout          = 2880
  max_retries          = 1
  max_concurrent_runs  = 1
  log_retention_days   = 7
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
}

enable_versioning = true

lake_formation = {
  enable               = false
  database_permissions = ["CREATE_TABLE"]
}
```

### 4. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## ⚙️ Configuration

### Main Variables

#### General Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `project_name` | Project name for resource naming | `"glue-csv-to-json"` | No |
| `region` | AWS region for deployment | `"eu-west-1"` | No |
| `tags` | Common tags for all resources | `{}` | No |

#### Glue Job Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `script_path` | Path to Glue ETL script in S3 | `"scripts/glue-etl-job.py"` | No |
| `input_table_prefix` | Prefix for input tables | `"raw_"` | No |
| `output_path` | S3 path for processed output | `"output/"` | No |
| `output_format` | Output format (json, parquet, csv, orc) | `"json"` | No |
| `worker_type` | Glue worker type | `"G.1X"` | No |
| `number_of_workers` | Number of Glue workers | `2` | No |
| `version` | Glue version | `"5.0"` | No |
| `job_timeout` | Job timeout in minutes | `2880` | No |
| `max_retries` | Maximum job retries | `1` | No |
| `max_concurrent_runs` | Maximum concurrent job runs | `1` | No |
| `log_retention_days` | CloudWatch log retention | `1` | No |
| `enable_quality_checks` | Enable data quality checks | `true` | No |
| `quality_report_path` | S3 path for quality reports | `"quality-reports/"` | No |
| `bad_data_path` | S3 path for bad data | `"bad-data/"` | No |
| `filter_bad_data` | Filter and store bad data | `true` | No |
| `job_bookmark_option` | Job bookmark mode | `"job-bookmark-disable"` | No |
| `enable_partitioning` | Enable time-based partitioning | `true` | No |
| `partition_columns` | Partition columns (comma-separated) | `"year,month,day"` | No |
| `enable_job_insights` | Enable Glue job insights | `true` | No |
| `enable_spark_ui` | Enable Spark UI | `true` | No |
| `job_language` | Script language (python, scala) | `"python"` | No |
| `python_version` | Python version (2 or 3) | `"3"` | No |

#### Other Configuration

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `enable_versioning` | Enable S3 bucket versioning | `true` | No |
| `crawler_schedule` | Crawler schedule (cron/rate) | `null` | No |
| `lake_formation.enable` | Enable Lake Formation | `false` | No |
| `lake_formation.database_permissions` | LF database permissions | `["CREATE_TABLE"]` | No |

## 📖 Usage

### Basic Usage

1. **Upload Raw Data**: Place your CSV/JSON files in the raw data S3 bucket
2. **Run Crawler**: The crawler will discover and catalog the data
3. **ETL Job Executes**: Automatically triggered after crawler succeeds
4. **Check Output**: Processed data is in the output S3 bucket

### Manual Execution

```bash
# Start the workflow manually
aws glue start-workflow-run --name <project-name>-workflow

# Or run individual components
aws glue start-crawler --name <project-name>-crawler
aws glue start-job-run --job-name <project-name>-csv-to-json
```

### Output Formats

The pipeline supports multiple output formats:

- **JSON**: `output_format = "json"`
- **Parquet**: `output_format = "parquet"` (recommended for analytics)
- **CSV**: `output_format = "csv"`
- **ORC**: `output_format = "orc"`

### Partitioning

Data is automatically partitioned by processing time:

```
s3://bucket/output/table_name/
  └── year=2024/
      └── month=1/
          └── day=25/
              └── part-*.json
```

Query in Athena:
```sql
SELECT * FROM table_name
WHERE year = 2024 AND month = 1 AND day = 25
```

## 🧩 Modules

### S3 Module (`modules/s3`)
- Creates raw data and processed data S3 buckets
- Uploads Glue scripts (Python and Scala)
- Configurable versioning

### IAM Module (`modules/iam`)
- Creates Glue service role
- Grants S3, Glue Catalog, and CloudWatch permissions
- Optional Lake Formation permissions

### Glue Database Module (`modules/glue-database`)
- Creates Glue Catalog database
- Required for crawler and Lake Formation

### Glue Crawler Module (`modules/glue-crawler`)
- Discovers data schema
- Creates tables in Glue Catalog
- Optional Lake Formation integration
- Configurable schedule

### Glue Job Module (`modules/glue-job`)
- Creates ETL job with PySpark/Spark script
- Configurable workers, timeout, retries
- Creates workflow and triggers

### Lake Formation Module (`modules/lake-formation`) (Optional)
- Registers S3 location
- Grants data location and database permissions

## 📤 Outputs

After applying, you can access:

```hcl
# S3 Buckets
output.raw_data_bucket_name
output.processed_data_bucket_name

# IAM
output.glue_service_role_arn

# Glue
output.crawler_name
output.job_name
output.workflow_name
output.database_name
```

## 🔍 Data Quality

### Quality Checks

The pipeline performs comprehensive quality checks:

- **Duplicate Detection**: Identifies and optionally filters duplicate records
- **Null Validation**: Detects null values and empty strings
- **Quality Scoring**: Calculates quality score (0-100)
- **Column-level Metrics**: Per-column statistics

### Quality Reports

Quality reports are generated as JSON files:

```json
{
  "table_name": "raw_sales",
  "timestamp": "2024-01-25T16:06:01",
  "total_records": 18,
  "duplicates": 0,
  "null_records": 0,
  "quality_score": 100.0,
  "columns": [...]
}
```

### Bad Data Handling

When `filter_bad_data = true`:
- Duplicate records are filtered to `bad-data/` path
- Records with nulls are removed from clean data
- Bad data is stored separately for analysis

## 🔐 Lake Formation

### Enable Lake Formation

```hcl
lake_formation = {
  enable               = true
  database_permissions = ["CREATE_TABLE", "ALTER_TABLE"]
}
```

### Manual Setup

If you prefer manual setup, see `LAKE_FORMATION_SETUP.my-local.md` for console steps.

## 🐛 Troubleshooting

### Common Issues

#### Job Fails with Permission Errors
- Check IAM role has `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` permissions
- Verify Lake Formation permissions if enabled

#### No Tables Found
- Ensure raw data files are in the correct S3 bucket
- Check table prefix matches your file naming convention
- Verify crawler has run successfully

#### Quality Reports Not Generated
- Check `enable_quality_checks = true`
- Verify S3 write permissions for quality report path
- Check CloudWatch logs for errors

#### Partitioning Not Working
- Ensure `enable_partitioning = true`
- Check partition columns are valid: `year`, `month`, `day`, `hour`, `minute`
- Verify output format supports partitioning (all formats do)

### Debugging

1. **Check CloudWatch Logs**:
   ```bash
   aws logs tail /aws-glue/<project-name> --follow
   ```

2. **View Job Run Details**:
   ```bash
   aws glue get-job-run --job-name <job-name> --run-id <run-id>
   ```

3. **Check Spark UI**: Enable `enable_spark_ui = true` and access via Glue console

4. **Review Quality Reports**: Check S3 bucket for quality report JSON files

## 📝 Example Configurations

### Minimal Configuration

```hcl
project_name = "my-etl"
glue_job = {
  script_path = "scripts/glue-etl-job.py"
  # All other values use defaults
}
```

### Production Configuration

```hcl
project_name = "prod-etl"
region       = "us-east-1"

glue_job = {
  script_path          = "scripts/glue-etl-job.py"
  output_format        = "parquet"  # Better for analytics
  worker_type          = "G.2X"     # More memory
  number_of_workers    = 10
  job_timeout          = 2880
  max_retries          = 3
  log_retention_days   = 30
  enable_quality_checks = true
  enable_partitioning   = true
  partition_columns     = "year,month,day"
}

enable_versioning = true

lake_formation = {
  enable               = true
  database_permissions = ["CREATE_TABLE", "ALTER_TABLE", "DROP_TABLE"]
}
```

### Scala Configuration

```hcl
glue_job = {
  script_path   = "scripts/glue-etl-job.scala"
  job_language  = "scala"
  python_version = "3"  # Ignored for Scala, but required
}
```

## 🔄 Workflow

The pipeline follows this workflow:

1. **Trigger**: Workflow starts (manual or scheduled)
2. **Crawler**: Discovers and catalogs raw data
3. **Conditional Trigger**: Job starts after crawler succeeds
4. **ETL Processing**:
   - Reads data from Glue Catalog
   - Performs quality checks
   - Transforms to output format
   - Partitions by processing time
   - Writes to S3
5. **Completion**: Quality reports generated, job bookmark committed

## 📚 Additional Resources

- [AWS Glue Documentation](https://docs.aws.amazon.com/glue/)
- [AWS Glue Best Practices](https://docs.aws.amazon.com/glue/latest/dg/best-practices.html)
- [Lake Formation Documentation](https://docs.aws.amazon.com/lake-formation/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 📄 License

This project is provided as-is for educational and production use.

## 🤝 Contributing

Contributions are welcome! Please ensure:
- Code follows existing patterns
- All tests pass
- Documentation is updated

---

**Note**: This module creates AWS resources that may incur costs. Always review and understand the resources being created before applying.
