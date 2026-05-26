provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "cognito" {
  source       = "./modules/cognito"
  project_name = var.project_name
  environment  = var.environment
}

module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
  environment  = var.environment
}

module "ec2" {
  source             = "./modules/ec2"
  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_instance_type  = var.ec2_instance_type
  ec2_ami_id         = var.ec2_ami_id
  key_pair_name      = var.key_pair_name
  s3_bucket_name     = var.s3_bucket_name
}

module "api_gateway" {
  source                = "./modules/api_gateway"
  project_name          = var.project_name
  environment           = var.environment
  lambda_invoke_arn     = module.lambda.invoke_arn
  lambda_function_name  = module.lambda.function_name
  cognito_user_pool_arn = module.cognito.user_pool_arn
  cognito_client_id     = module.cognito.client_id
}

module "glue" {
  source         = "./modules/glue"
  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name
}

module "step_functions" {
  source         = "./modules/step_functions"
  project_name   = var.project_name
  environment    = var.environment
  s3_bucket_name = var.s3_bucket_name
}