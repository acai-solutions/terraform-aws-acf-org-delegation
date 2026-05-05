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

  # On AWS ESC there is no us-east-1; only the primary region is deployed.
  is_commercial     = var.aws_partition == "aws"
  secondary_regions = local.is_commercial ? ["us-east-1"] : []
  all_regions       = concat([local.primary_aws_region], local.secondary_regions)

  # Service principals always use amazonaws.com regardless of partition/endpoint domain.
  # Each delegation declares the regions it should be applied in; preprocess-data pivots
  # this list into a per-region map consumed by the per-region module instantiations below.
  delegations = concat(
    [
      {
        regions           = local.all_regions
        service_principal = "cloudtrail.amazonaws.com"
        target_account_id = var.account_ids.core_security
      },
      {
        regions           = local.all_regions
        service_principal = "config.amazonaws.com"
        target_account_id = var.account_ids.core_security
      },
      {
        regions           = local.all_regions
        service_principal = "guardduty.amazonaws.com"
        target_account_id = var.account_ids.core_security
      },
      {
        regions           = local.all_regions
        service_principal = "securityhub.amazonaws.com"
        target_account_id = var.account_ids.core_security
      },
      {
        regions           = local.all_regions
        service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
        target_account_id = var.account_ids.core_security
      },
      {
        regions           = local.all_regions
        service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
        target_account_id = var.account_ids.core_logging
      },
    ],
    # backup delegation is only available on AWS commercial partition
    local.is_commercial ? [{
      regions           = local.all_regions
      service_principal = "backup.amazonaws.com"
      target_account_id = var.account_ids.core_security
    }] : []
  )
}

module "preprocess_data" {
  source = "../../modules/preprocess-data"

  primary_aws_region = local.primary_aws_region
  delegations        = local.delegations
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ PRIMARY REGION (both AWS commercial and AWS ESC)
# ---------------------------------------------------------------------------------------------------------------------
module "example_primary" {
  source = "../../"

  preprocessed_data = {
    primary_aws_region = local.primary_aws_region
    current_aws_region = local.primary_aws_region
    delegations        = module.preprocess_data.delegations_by_region[local.primary_aws_region]
  }
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
    aws = aws.org_mgmt_primary
  }
  depends_on = [module.create_provisioner]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ SECONDARY REGION - us-east-1 (AWS commercial only)
# ---------------------------------------------------------------------------------------------------------------------
module "example_use1" {
  source = "../../"
  count  = local.is_commercial ? 1 : 0

  preprocessed_data = {
    primary_aws_region = local.primary_aws_region
    current_aws_region = "us-east-1"
    delegations        = module.preprocess_data.delegations_by_region["us-east-1"]
  }
  providers = {
    aws = aws.org_mgmt_use1
  }
  depends_on = [module.example_primary]
}
