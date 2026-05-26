# IAM role for Glue
resource "aws_iam_role" "glue" {
  name = "${var.project_name}-${var.environment}-glue-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "glue.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3" {
  role       = aws_iam_role.glue.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy" "glue_ssm" {
  role = aws_iam_role.glue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:PutParameter", "ssm:GetParameter"]
      Resource = "arn:aws:ssm:us-east-1:*:parameter/ml-pipeline/*"
    }]
  })
}

# Glue catalog database
resource "aws_glue_catalog_database" "main" {
  name = "${var.project_name}_${var.environment}_db"
}

# Job 1 - Clean CSV
resource "aws_glue_job" "job1_clean" {
  name     = "${var.project_name}-${var.environment}-job1-clean"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.s3_bucket_name}/glue-scripts/job1_clean.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--S3_INPUT_PATH"                    = "s3://${var.s3_bucket_name}/raw/"
    "--S3_OUTPUT_PATH"                   = "s3://${var.s3_bucket_name}/cleaned/"
    "--TempDir"                          = "s3://${var.s3_bucket_name}/glue-temp/"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}

# Job 2 - Convert to Parquet
resource "aws_glue_job" "job2_parquet" {
  name     = "${var.project_name}-${var.environment}-job2-parquet"
  role_arn = aws_iam_role.glue.arn

  command {
    name            = "glueetl"
    script_location = "s3://${var.s3_bucket_name}/glue-scripts/job2_parquet.py"
    python_version  = "3"
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--S3_INPUT_PATH"                    = "s3://${var.s3_bucket_name}/cleaned/"
    "--S3_OUTPUT_PATH"                   = "s3://${var.s3_bucket_name}/parquet/"
    "--TempDir"                          = "s3://${var.s3_bucket_name}/glue-temp/"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}

# Glue Workflow
resource "aws_glue_workflow" "main" {
  name = "${var.project_name}-${var.environment}-etl-workflow"
}

# Trigger to start Job 1 (on demand)
resource "aws_glue_trigger" "start_job1" {
  name          = "${var.project_name}-${var.environment}-trigger-job1"
  type          = "ON_DEMAND"
  workflow_name = aws_glue_workflow.main.name

  actions {
    job_name = aws_glue_job.job1_clean.name
  }
}

# Trigger to start Job 2 when Job 1 succeeds
resource "aws_glue_trigger" "start_job2" {
  name          = "${var.project_name}-${var.environment}-trigger-job2"
  type          = "CONDITIONAL"
  workflow_name = aws_glue_workflow.main.name

  predicate {
    conditions {
      job_name = aws_glue_job.job1_clean.name
      state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.job2_parquet.name
  }
}