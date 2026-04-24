# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


# ---------------------------------------------------------------------------------------------------------------------
# ¦ VERSIONS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------

locals {
  primary_aws_region = var.aws_region
  default_regions    = var.aws_region != "eu-central-1" ? [var.aws_region] : ["eu-central-1", "us-east-2"]
  global_region      = var.aws_region != "eu-central-1" ? var.aws_region : "us-east-1"
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ CREATE PROVISIONER
# ---------------------------------------------------------------------------------------------------------------------
module "create_provisioner" {
  source = "../../cicd-principals/terraform"

  iam_role_settings = {
    name = "org_delegation_cicd_provisioner"
    aws_trustee_arns = [
      "arn:${var.aws_partition}:iam::${var.account_ids.org_mgmt}:root"
    ]
  }
  providers = {
    aws = aws.org_mgmt
  }
}

provider "aws" {
  region = local.primary_aws_region
  alias  = "org_mgmt_primary_region"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}

provider "aws" {
  region = local.global_region
  alias  = "org_mgmt_global_region"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------
locals {
  delegations = [
    {
      regions           = [local.global_region]
      service_principal = "cloudtrail.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "config.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = local.default_regions
      service_principal = "guardduty.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = local.default_regions
      service_principal = "securityhub.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "backup.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "member.org.stacksets.cloudformation.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "member.org.stacksets.cloudformation.${var.aws_endpoint_domain}"
      target_account_id = var.account_ids.core_logging
    }
  ]
}

module "preprocess_data" {
  source = "../../modules/preprocess-data"

  primary_aws_region = local.primary_aws_region
  delegations        = local.delegations
}

module "example_primary" {
  source = "../../"

  primary_aws_region = module.preprocess_data.is_primary_region[local.primary_aws_region]
  delegations        = module.preprocess_data.delegations_by_region[local.primary_aws_region]
  providers = {
    aws = aws.org_mgmt_primary_region
  }
  depends_on = [module.create_provisioner]
}


module "example_global" {
  source = "../../"

  primary_aws_region = module.preprocess_data.is_primary_region[local.global_region]
  aws_organizations_resource_policy = {
    content_as_json = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowOrganizationsRead",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:${var.aws_partition}:iam::${var.account_ids.core_logging}:root"
          },
          "Action" : [
            "organizations:Describe*",
            "organizations:List*"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "AllowBackupPoliciesCreation",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:${var.aws_partition}:iam::${var.account_ids.core_logging}:root"
          },
          "Action" : "organizations:CreatePolicy",
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "organizations:PolicyType" : "BACKUP_POLICY"
            }
          }
        }
      ]
    })
    resource_tags = {
      "test" : "tag"
      "test2" : "tag"
    }
  }
  providers = {
    aws = aws.org_mgmt_global_region
  }
  depends_on = [
    module.create_provisioner,
  ]
}
