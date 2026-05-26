import sys
import boto3
from datetime import datetime
from awsglue.utils import getResolvedOptions
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.context import SparkContext
from pyspark.sql import functions as F

# Get job arguments
args = getResolvedOptions(sys.argv, ["JOB_NAME", "S3_INPUT_PATH", "S3_OUTPUT_PATH"])

sc          = SparkContext()
glueContext = GlueContext(sc)
spark       = glueContext.spark_session
job         = Job(glueContext)
job.init(args["JOB_NAME"], args)

INPUT_PATH  = args["S3_INPUT_PATH"]
OUTPUT_PATH = args["S3_OUTPUT_PATH"]

print(f"Reading from: {INPUT_PATH}")

# 1. Load CSV
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(INPUT_PATH)

print(f"Row count before cleaning: {df.count()}")

# 2. Drop duplicate rows
df = df.dropDuplicates()

# 3. Drop rows where all columns are null
df = df.dropna(how="all")

# 4. Fill null numeric values with 0
df = df.fillna(0)

# 5. Add a cleaned_at column
df = df.withColumn("cleaned_at", F.lit(datetime.utcnow().isoformat()))

print(f"Row count after cleaning: {df.count()}")

# 6. Write cleaned CSV back to S3
run_ts     = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
output_key = f"{OUTPUT_PATH.rstrip('/')}/{run_ts}/"

df.coalesce(1).write \
    .mode("overwrite") \
    .option("header", "true") \
    .csv(output_key)

print(f"Cleaned data written to: {output_key}")

# 7. Save output path to SSM for Job 2
ssm = boto3.client("ssm", region_name="us-east-1")
ssm.put_parameter(
    Name="/ml-pipeline/glue/job1-output-path",
    Value=output_key,
    Type="String",
    Overwrite=True
)
print("Output path saved to SSM")

job.commit()
print("Job 1 complete")