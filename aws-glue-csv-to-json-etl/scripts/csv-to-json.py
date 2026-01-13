import sys
import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext

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

# Discover catalog tables with the specified prefix
client = boto3.client("glue")
next_token = None
matching_tables = []

while True:
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

if not matching_tables:
    print(f"No tables found in database '{input_db}' with prefix '{prefix}'.")
else:
    print(f"Found tables: {matching_tables}")

# Process each matching table: read CSV via Data Catalog and write JSON to S3
for table_name in matching_tables:
    print(f"Processing table: {table_name}")
    dyf = glueContext.create_dynamic_frame.from_catalog(
        database=input_db,
        table_name=table_name,
        transformation_ctx=f"dyf_{table_name}"
    )

    # Convert to Spark DataFrame and write JSON
    df = dyf.toDF()
    target = f"s3://{output_bucket}/{output_path}/{table_name}/"
    (
        df.write
        .mode("overwrite")  # overwrite per run; adjust if needed
        .json(target)
    )
    print(f"Wrote JSON to {target}")

job.commit()
