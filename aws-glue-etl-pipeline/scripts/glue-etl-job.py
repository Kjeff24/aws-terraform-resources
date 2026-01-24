import sys
import json
import traceback
import boto3
from datetime import datetime
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StructType, StructField, StringType, IntegerType, DoubleType, DateType, TimestampType
from botocore.exceptions import ClientError

# Partition column mapping for processing time
PARTITION_COLUMN_MAP = {
    "year": lambda ts: F.year(ts),
    "month": lambda ts: F.month(ts),
    "day": lambda ts: F.dayofmonth(ts),
    "hour": lambda ts: F.hour(ts),
    "minute": lambda ts: F.minute(ts),
}

# Expected job arguments passed from Terraform default_arguments
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "input_database",
        "input_table_prefix",
        "output_bucket",
        "output_path",
        "output_format",
        "enable_quality_checks",
        "quality_report_path",
        "bad_data_path",
        "filter_bad_data",
        "enable_partitioning",
        "partition_columns",
    ],
)

sc = SparkContext()
sc.setLogLevel("WARN")

glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

input_db = args["input_database"]
prefix = args["input_table_prefix"]
output_bucket = args["output_bucket"]
output_path = args["output_path"].rstrip("/")
output_format = args.get("output_format", "json").lower()
enable_quality_checks = args.get("enable_quality_checks", "false").lower() == "true"
quality_report_path = args.get("quality_report_path", "quality-reports/").rstrip("/")
bad_data_path = args.get("bad_data_path", "bad-data/").rstrip("/")
filter_bad_data = args.get("filter_bad_data", "false").lower() == "true"
enable_partitioning = args.get("enable_partitioning", "false").lower() == "true"
partition_columns_str = args.get("partition_columns", "year,month,day")
partition_columns = [col.strip() for col in partition_columns_str.split(",")] if enable_partitioning else []

# Supported output formats
SUPPORTED_FORMATS = ["json", "parquet", "csv", "orc"]
if output_format not in SUPPORTED_FORMATS:
    raise ValueError(f"Unsupported output format: {output_format}. Supported formats: {SUPPORTED_FORMATS}")

def add_partition_columns(df, partition_cols):
    """
    Add processing time partition columns to DataFrame.
    Returns DataFrame with partition columns added.
    """
    if not partition_cols:
        return df
    
    df_with_partitions = df
    processing_timestamp = F.current_timestamp()
    
    for col_name in partition_cols:
        col_name_lower = col_name.lower()
        if col_name_lower in PARTITION_COLUMN_MAP:
            df_with_partitions = df_with_partitions.withColumn(
                col_name_lower,
                PARTITION_COLUMN_MAP[col_name_lower](processing_timestamp)
            )
        else:
            print(f"WARNING: Unknown partition column '{col_name}', skipping.")
    
    return df_with_partitions

def perform_quality_checks(df, table_name):
    """
    Perform comprehensive data quality checks on a DataFrame.
    Returns quality metrics dictionary and DataFrame with quality flags.
    """
    metrics = {
        "table_name": table_name,
        "timestamp": datetime.utcnow().isoformat(),
        "total_records": df.count(),
        "columns": [],
        "duplicates": 0,
        "null_records": 0,
        "quality_score": 0.0
    }
    
    if metrics["total_records"] == 0:
        metrics["quality_score"] = 0.0
        return metrics, df
    
    # Get schema information
    schema = df.schema
    column_names = df.columns
    
    # Calculate column-level statistics
    for col_name in column_names:
        col_metrics = {
            "column_name": col_name,
            "data_type": str(schema[col_name].dataType),
            "null_count": 0,
            "null_percentage": 0.0,
            "distinct_count": 0,
            "empty_string_count": 0
        }
        
        # Count nulls
        null_count = df.filter(F.col(col_name).isNull()).count()
        col_metrics["null_count"] = null_count
        col_metrics["null_percentage"] = (null_count / metrics["total_records"]) * 100
        
        # Count distinct values
        distinct_count = df.select(col_name).distinct().count()
        col_metrics["distinct_count"] = distinct_count
        
        # Count empty strings (for string columns)
        if isinstance(schema[col_name].dataType, StringType):
            empty_count = df.filter((F.col(col_name) == "") | (F.col(col_name).isNull())).count()
            col_metrics["empty_string_count"] = empty_count
        
        metrics["columns"].append(col_metrics)
    
    # Detect duplicates (based on all columns)
    duplicate_count = df.count() - df.distinct().count()
    metrics["duplicates"] = duplicate_count
    
    # Count records with any null values
    null_condition = F.lit(False)
    for col_name in column_names:
        null_condition = null_condition | F.col(col_name).isNull()
    metrics["null_records"] = df.filter(null_condition).count()
    
    # Calculate quality score (0-100)
    # Penalize: nulls, duplicates, empty records
    null_penalty = (metrics["null_records"] / metrics["total_records"]) * 50 if metrics["total_records"] > 0 else 0
    duplicate_penalty = (duplicate_count / metrics["total_records"]) * 30 if metrics["total_records"] > 0 else 0
    empty_penalty = sum(col["empty_string_count"] for col in metrics["columns"]) / metrics["total_records"] * 20 if metrics["total_records"] > 0 else 0
    
    metrics["quality_score"] = max(0.0, 100.0 - null_penalty - duplicate_penalty - empty_penalty)
    
    return metrics, df

def write_quality_report(metrics, output_bucket, report_path, table_name):
    """Write quality report to S3 as JSON."""
    s3_client = boto3.client("s3")
    report_key = f"{report_path}/{table_name}_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
    
    try:
        report_json = json.dumps(metrics, indent=2)
        s3_client.put_object(
            Bucket=output_bucket,
            Key=report_key,
            Body=report_json,
            ContentType="application/json"
        )
        print(f"Quality report written to: s3://{output_bucket}/{report_key}")
        return report_key
    except Exception as e:
        print(f"WARNING: Failed to write quality report: {str(e)}")
        return None

# Discover catalog tables with the specified prefix
matching_tables = []
failed_tables = []
processed_count = 0
quality_reports = []

try:
    client = boto3.client("glue")
    next_token = None
    
    print(f"Discovering tables in database '{input_db}' with prefix '{prefix}'...")
    print(f"Quality checks: {'ENABLED' if enable_quality_checks else 'DISABLED'}")
    if enable_quality_checks:
        print(f"Quality reports path: s3://{output_bucket}/{quality_report_path}/")
        print(f"Bad data filtering: {'ENABLED' if filter_bad_data else 'DISABLED'}")
        if filter_bad_data:
            print(f"Bad data path: s3://{output_bucket}/{bad_data_path}/")
    
    while True:
        try:
            if next_token:
                resp = client.get_tables(DatabaseName=input_db, NextToken=next_token)
            else:
                resp = client.get_tables(DatabaseName=input_db)
            
            for tbl in resp.get("TableList", []):
                name = tbl.get("Name", "")
                if name.startswith(prefix):
                    matching_tables.append(name)
            
            next_token = resp.get("NextToken")
            if not next_token:
                break
        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            print(f"ERROR: Failed to get tables from Glue Catalog: {error_code} - {error_msg}")
            raise
        except Exception as e:
            print(f"ERROR: Unexpected error while discovering tables: {str(e)}")
            raise

    if not matching_tables:
        print(f"WARNING: No tables found in database '{input_db}' with prefix '{prefix}'.")
        print("Job will complete successfully but no data was processed.")
    else:
        print(f"Found {len(matching_tables)} table(s): {matching_tables}")

    # Process each matching table
    print(f"\nOutput format: {output_format.upper()}")
    for table_name in matching_tables:
        try:
            print(f"\n{'='*60}")
            print(f"Processing table: {table_name}")
            print(f"{'='*60}")
            
            # Read from Glue Data Catalog
            dyf = glueContext.create_dynamic_frame.from_catalog(
                database=input_db,
                table_name=table_name,
                transformation_ctx=f"dyf_{table_name}"
            )
            
            # Convert to Spark DataFrame
            df = dyf.toDF()
            original_count = df.count()
            print(f"Records found in table '{table_name}': {original_count}")
            
            if original_count == 0:
                print(f"WARNING: Table '{table_name}' is empty. Skipping {output_format.upper()} output.")
                continue
            
            # Perform quality checks if enabled
            quality_metrics = None
            df_clean = df
            df_bad = None
            
            if enable_quality_checks:
                print("\n--- Running Data Quality Checks ---")
                quality_metrics, df_checked = perform_quality_checks(df, table_name)
                
                print(f"Quality Score: {quality_metrics['quality_score']:.2f}/100")
                print(f"Total Records: {quality_metrics['total_records']}")
                print(f"Duplicate Records: {quality_metrics['duplicates']}")
                print(f"Records with Nulls: {quality_metrics['null_records']}")
                
                # Print column-level metrics
                for col_metric in quality_metrics["columns"]:
                    if col_metric["null_count"] > 0 or col_metric["empty_string_count"] > 0:
                        print(f"  Column '{col_metric['column_name']}': "
                              f"{col_metric['null_count']} nulls ({col_metric['null_percentage']:.2f}%), "
                              f"{col_metric['empty_string_count']} empty strings")
                
                # Filter bad data if enabled
                if filter_bad_data:
                    # Identify bad records: duplicates or records with nulls in critical columns
                    # For simplicity, we'll mark duplicates as bad data
                    # You can customize this logic based on your requirements
                    df_clean = df_checked.dropDuplicates()
                    duplicate_count = original_count - df_clean.count()
                    
                    if duplicate_count > 0:
                        # Get duplicate records
                        df_bad = df_checked.subtract(df_clean)
                        bad_count = df_bad.count()
                        print(f"\nFiltered {bad_count} bad record(s) (duplicates)")
                        
                        # Add partition columns if enabled
                        if enable_partitioning:
                            df_bad = add_partition_columns(df_bad, partition_columns)
                        
                        # Write bad data to separate location
                        bad_target = f"s3://{output_bucket}/{bad_data_path}/{table_name}/"
                        print(f"Writing bad data to: {bad_target}")
                        write_mode = "append" if enable_partitioning else "overwrite"
                        writer_bad = df_bad.write.mode(write_mode)
                        
                        if enable_partitioning and partition_columns:
                            writer_bad = writer_bad.partitionBy(*[col.lower() for col in partition_columns])
                        
                        if output_format == "json":
                            writer_bad.json(bad_target)
                        elif output_format == "parquet":
                            writer_bad.parquet(bad_target)
                        elif output_format == "csv":
                            writer_bad.option("header", "true").csv(bad_target)
                        elif output_format == "orc":
                            writer_bad.orc(bad_target)
                    
                    df_clean = df_clean.dropna()  # Remove records with any nulls
                    final_count = df_clean.count()
                    removed_count = original_count - final_count
                    if removed_count > 0:
                        print(f"Removed {removed_count} record(s) with null values")
                else:
                    df_clean = df_checked
                
                # Write quality report
                report_key = write_quality_report(quality_metrics, output_bucket, quality_report_path, table_name)
                if report_key:
                    quality_reports.append(report_key)
            
            # Add partition columns if enabled
            if enable_partitioning:
                df_clean = add_partition_columns(df_clean, partition_columns)
                print(f"Partitioning enabled: {', '.join(partition_columns)}")
            
            # Write clean/good data
            target = f"s3://{output_bucket}/{output_path}/{table_name}/"
            final_count = df_clean.count()
            
            print(f"\nWriting {output_format.upper()} to: {target}")
            print(f"Records to write: {final_count}")
            
            # Use append mode when partitioning to preserve historical data
            write_mode = "append" if enable_partitioning else "overwrite"
            writer = df_clean.write.mode(write_mode)
            
            # Add partitionBy when partitioning is enabled
            if enable_partitioning and partition_columns:
                writer = writer.partitionBy(*[col.lower() for col in partition_columns])
                print(f"Partitioning by: {', '.join([col.lower() for col in partition_columns])}")
            
            if output_format == "json":
                writer.json(target)
            elif output_format == "parquet":
                writer.parquet(target)
            elif output_format == "csv":
                writer.option("header", "true").csv(target)
            elif output_format == "orc":
                writer.orc(target)
            
            print(f"Successfully wrote {final_count} records to {target} in {output_format.upper()} format")
            processed_count += 1
            
        except Exception as e:
            error_traceback = traceback.format_exc()
            error_msg = f"ERROR: Failed to process table '{table_name}': {str(e)}"
            print(error_msg)
            print(f"Traceback:\n{error_traceback}")
            failed_tables.append({
                "table": table_name,
                "error": str(e),
                "traceback": error_traceback
            })
            continue

    # Summary
    print(f"\n{'='*60}")
    print("JOB SUMMARY")
    print(f"{'='*60}")
    print(f"Total tables found: {len(matching_tables)}")
    print(f"Successfully processed: {processed_count}")
    print(f"Failed: {len(failed_tables)}")
    
    if enable_quality_checks and quality_reports:
        print(f"\nQuality reports generated: {len(quality_reports)}")
        for report in quality_reports:
            print(f"  - s3://{output_bucket}/{report}")
    
    if failed_tables:
        print("\nFailed tables:")
        error_details = []
        for failed in failed_tables:
            error_info = f"  - {failed['table']}: {failed['error']}"
            print(error_info)
            error_details.append(error_info)
        
        # Include error details in exception message for better visibility
        error_summary = f"Job completed with {len(failed_tables)} table(s) failed:\n" + "\n".join(error_details)
        raise Exception(error_summary)
    
    if processed_count == 0 and len(matching_tables) > 0:
        print("WARNING: No tables were successfully processed.")
    
    print(f"{'='*60}\n")

except Exception as e:
    print(f"\n{'='*60}")
    print(f"FATAL ERROR: {str(e)}")
    print(f"{'='*60}")
    raise

finally:
    # Always commit job bookmark - safe even if bookmarks are disabled
    # AWS Glue handles bookmark state automatically when enabled
    job.commit()
    print("Job bookmark committed.")
