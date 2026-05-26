# AWS ML Pipeline

End-to-end machine learning pipeline built on AWS using Terraform.

## Architecture

API Gateway → Lambda → Cognito (Auth)
API Gateway → VPC Link → ALB → EC2 (Spring Boot) → S3

S3 Upload → EventBridge → Step Functions → Glue ETL → SageMaker Training → SageMaker Endpoint

## Stack

- **Terraform** — infrastructure as code
- **AWS Lambda** — serverless compute
- **AWS Cognito** — authentication
- **AWS VPC** — networking
- **EC2 + Spring Boot** — file upload service
- **AWS S3** — data storage
- **AWS Glue** — ETL (clean CSV → Parquet)
- **AWS Step Functions** — pipeline orchestration
- **AWS SageMaker** — model training and serving

## Structure
├── terraform/        # All infrastructure code
│   └── modules/      # VPC, Lambda, EC2, Cognito, Glue, Step Functions
├── spring-boot/      # File upload service
├── glue/             # ETL job scripts
├── step_functions/   # State machine definition
├── lambda_src/       # Lambda handler
└── scripts/          # Data generation script

## How to run

1. `cd terraform && terraform init && terraform apply`
2. `cd spring-boot && mvn clean package && java -jar target/file-upload-1.0.0.jar`
3. `cd scripts && python3 generate_and_upload.py`