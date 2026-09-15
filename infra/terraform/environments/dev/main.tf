terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "project_name" {
  description = "Project name used as a naming prefix."
  type        = string
  default     = "oficina"
}

variable "environment" {
  description = "Infrastructure environment name."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Output vpc_id do repositorio oficina-infra-k8s (terraform output -raw vpc_id) — o RDS precisa estar na mesma VPC do cluster."
  type        = string
}

variable "subnet_ids" {
  description = "Output subnet_ids do repositorio oficina-infra-k8s (terraform output -json subnet_ids)."
  type        = list(string)
}

variable "db_username" {
  description = "Database admin username."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database admin password."
  type        = string
  sensitive   = true
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Repo        = "oficina-infra-db"
  }
}

module "postgres_db" {
  source = "../../modules/postgres-db"

  name_prefix         = local.name_prefix
  vpc_id              = var.vpc_id
  subnet_ids          = var.subnet_ids
  username            = var.db_username
  password            = var.db_password
  allowed_cidr_blocks = ["10.0.0.0/16"]
  tags                = local.tags
}

output "db_endpoint" {
  value       = module.postgres_db.db_endpoint
  description = "Provisioned PostgreSQL endpoint (consumido pelo repo oficina-app via SPRING_DATASOURCE_URL)."
}

output "db_port" {
  value = module.postgres_db.db_port
}

output "db_name" {
  value = module.postgres_db.db_name
}

output "db_username" {
  value = module.postgres_db.db_username
}

output "security_group_id" {
  value       = module.postgres_db.security_group_id
  description = "Security group do RDS (para eventual regra de ingress adicional a partir do cluster)."
}
