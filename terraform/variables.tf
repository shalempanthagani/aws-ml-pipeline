variable "project_name"         { 
    type = string  
    default = "ml-pipeline"
    }
variable "environment"           { 
    type = string  
    default = "dev" 
    }
variable "aws_region"            {
     type = string  
     default = "us-east-1"
      }
variable "vpc_cidr"              { 
    type = string  
    default = "10.0.0.0/16" 
    }
variable "public_subnet_cidrs"   { 
    type = list(string)  
    default = ["10.0.1.0/24", "10.0.2.0/24"] 
    }
variable "private_subnet_cidrs"  { 
    type = list(string)  
    default = ["10.0.10.0/24", "10.0.11.0/24"] 
    }
variable "availability_zones"    { 
    type = list(string)  
    default = ["us-east-1a", "us-east-1b"] 
    }
variable "ec2_instance_type"     { 
    type = string  
    default = "t3.micro" 
    }
variable "ec2_ami_id"            { 
    type = string  
    default = "ami-0c02fb55956c7d316" 
    }
variable "key_pair_name"         { 
    type = string  
    default = "ml-pipeline-key" 
    }
variable "s3_bucket_name"        { 
    type = string  
    default = "ml-pipeline-dev-bucket" 
    }