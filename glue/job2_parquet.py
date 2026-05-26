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

OUTPUT_PATH = args["S3_OUTPUT_PATH"]

# 1. Get input path from SSM (set by Job 1)
ssm = boto3.client("ssm", region_name="us-east-1")
try:
    param      = ssm.get_parameter(Name="/ml-pipeline/glue/job1-output-path")
    INPUT_PATH = param["Parameter"]["Value"]
    print(f"Input path from SSM: {INPUT_PATH}")
except Exception:
    INPUT_PATH = args["S3_INPUT_PATH"]
    print(f"Falling back to arg input path: {INPUT_PATH}")

# 2. Load cleaned CSV
df = spark.read \
    .option("header", "true") \
    .option("inferSchema", "true") \
    .csv(INPUT_PATH)

print(f"Loaded {df.count()} rows")

# 3. Add partition columns
df = df \
    .withColumn("year",  F.lit(str(datetime.utcnow().year))) \
    .withColumn("month", F.lit(f"{datetime.utcnow().month:02d}")) \
    .withColumn("day",   F.lit(f"{datetime.utcnow().day:02d}"))

# 4. Write as Parquet
run_ts     = datetime.utcnow().strftime("%Y%m%dT%H%M%S")
output_key = f"{OUTPUT_PATH.rstrip('/')}/{run_ts}/"

df.write \
    .mode("overwrite") \
    .partitionBy("year", "month", "day") \
    .option("compression", "snappy") \
    .parquet(output_key)

print(f"Parquet written to: {output_key}")

# 5. Save output path to SSM for Step Function
ssm.put_parameter(
    Name="/ml-pipeline/glue/job2-output-path",
    Value=output_key,
    Type="String",
    Overwrite=True
)
print("Output path saved to SSM")

job.commit()
print("Job 2 complete")