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
  region = var.aws_region
  alias  = "org_mgmt_region"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ MODULE
# ---------------------------------------------------------------------------------------------------------------------
locals {
  # Service principals always use amazonaws.com regardless of partition/endpoint domain
  delegations = concat([
    {
      service_principal = "cloudtrail.amazonaws.com"
      target_account_id = var.account_ids.core_security
    },
    {
      service_principal = "config.amazonaws.com"
      target_account_id = var.account_ids.core_security
    },
    {
      service_principal = "guardduty.amazonaws.com"
      target_account_id = var.account_ids.core_security
    },
    {
      service_principal = "securityhub.amazonaws.com"
      target_account_id = var.account_ids.core_security
    },
    {
      service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
      target_account_id = var.account_ids.core_security
    },
    {
      service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
      target_account_id = var.account_ids.core_logging
    }
    ],
    # backup delegation is only available on standard AWS partition
    var.aws_partition == "aws" ? [{
      service_principal = "backup.amazonaws.com"
      target_account_id = var.account_ids.core_security
    }] : []
  )
}

module "example" {
  source = "../../"

  primary_aws_region = true
  delegations        = local.delegations
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
    aws = aws.org_mgmt_region
  }
  depends_on = [module.create_provisioner]
}
