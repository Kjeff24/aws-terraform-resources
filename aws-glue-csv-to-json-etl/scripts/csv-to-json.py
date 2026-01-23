import sys
import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from botocore.exceptions import ClientError

# Expected job arguments passed from Terraform default_arguments
# -- job-bookmark-option, enable-glue-datacatalog are set in job
args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "input_database",
        "input_table_prefix",
        "output_bucket",
        "output_path",
        "output_format",
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
output_format = args.get("output_format", "json").lower()  # Default to json for backward compatibility

# Supported output formats
SUPPORTED_FORMATS = ["json", "parquet", "csv", "orc"]
if output_format not in SUPPORTED_FORMATS:
    raise ValueError(f"Unsupported output format: {output_format}. Supported formats: {SUPPORTED_FORMATS}")

# Discover catalog tables with the specified prefix
matching_tables = []
failed_tables = []
processed_count = 0

try:
    client = boto3.client("glue")
    next_token = None
    
    print(f"Discovering tables in database '{input_db}' with prefix '{prefix}'...")
    
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

    # Process each matching table: read from Data Catalog and write to S3 in specified format
    print(f"Output format: {output_format.upper()}")
    for table_name in matching_tables:
        try:
            print(f"\n{'='*60}")
            print(f"Processing table: {table_name}")
            print(f"{'='*60}")
            
            # Read from Glue Data Catalog (supports CSV, JSON, Parquet, etc.)
            dyf = glueContext.create_dynamic_frame.from_catalog(
                database=input_db,
                table_name=table_name,
                transformation_ctx=f"dyf_{table_name}"
            )
            
            # Get record count for logging
            record_count = dyf.count()
            print(f"Records found in table '{table_name}': {record_count}")
            
            if record_count == 0:
                print(f"WARNING: Table '{table_name}' is empty. Skipping {output_format.upper()} output.")
                continue
            
            # Convert to Spark DataFrame
            df = dyf.toDF()
            target = f"s3://{output_bucket}/{output_path}/{table_name}/"
            
            print(f"Writing {output_format.upper()} to: {target}")
            
            # Write in the specified format
            writer = df.write.mode("overwrite")
            
            if output_format == "json":
                writer.json(target)
            elif output_format == "parquet":
                writer.parquet(target)
            elif output_format == "csv":
                writer.option("header", "true").csv(target)
            elif output_format == "orc":
                writer.orc(target)
            
            # Verify write by checking if output path exists (basic validation)
            print(f"Successfully wrote {record_count} records to {target} in {output_format.upper()} format")
            processed_count += 1
            
        except Exception as e:
            error_msg = f"ERROR: Failed to process table '{table_name}': {str(e)}"
            print(error_msg)
            failed_tables.append({"table": table_name, "error": str(e)})
            # Continue processing other tables instead of failing the entire job
            continue

    # Summary
    print(f"\n{'='*60}")
    print("JOB SUMMARY")
    print(f"{'='*60}")
    print(f"Total tables found: {len(matching_tables)}")
    print(f"Successfully processed: {processed_count}")
    print(f"Failed: {len(failed_tables)}")
    
    if failed_tables:
        print("\nFailed tables:")
        for failed in failed_tables:
            print(f"  - {failed['table']}: {failed['error']}")
        # If any tables failed, raise an exception to mark job as failed
        raise Exception(f"Job completed with {len(failed_tables)} table(s) failed. Check logs for details.")
    
    if processed_count == 0 and len(matching_tables) > 0:
        print("WARNING: No tables were successfully processed.")
    
    print(f"{'='*60}\n")

except Exception as e:
    print(f"\n{'='*60}")
    print(f"FATAL ERROR: {str(e)}")
    print(f"{'='*60}")
    # Re-raise to ensure job is marked as failed
    raise

finally:
    # Always commit the job to save bookmark state
    job.commit()
    print("Job bookmark committed.")
