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
  required_version = ">= 1.3.10"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.30"
      configuration_aliases = []
    }
  }
}


resource "aws_iam_role" "cicd_principal" {
  name                 = var.iam_role_settings.name
  path                 = var.iam_role_settings.path
  permissions_boundary = var.iam_role_settings.permissions_boundary_arn
  description          = "IAM Role used to provision the AWS Organization delegation"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  tags                 = var.resource_tags
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.iam_role_settings.aws_trustee_arns
    }
  }
}

resource "aws_iam_role_policy" "org_delegation" {
  name   = "OrganizationDelegation"
  role   = aws_iam_role.cicd_principal.id
  policy = data.aws_iam_policy_document.org_delegation_policy.json
}

#tfsec:ignore:AVD-AWS-0057
data "aws_iam_policy_document" "org_delegation_policy" {
  #checkov:skip=CKV_AWS_111 
  #checkov:skip=CKV_AWS_356 
  statement {
    effect = "Allow"
    actions = [
      "organizations:TagResource",
      "organizations:UntagResource"
    ]
    resources = ["arn:aws:organizations::*:resourcepolicy/*/rp-*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "organizations:TagResource",
      "organizations:UntagResource",

      "organizations:List*",
      "organizations:Describe*",
      "organizations:PutResourcePolicy",
      "organizations:DeleteResourcePolicy",
      "organizations:RegisterDelegatedAdministrator",
      "organizations:DeregisterDelegatedAdministrator",
      "organizations:EnableAWSServiceAccess",

      "securityhub:DescribeHub",
      "securityhub:ListOrganizationAdminAccounts",
      "securityhub:EnableSecurityHub",
      "securityhub:DisableSecurityHub",
      "securityhub:UpdateSecurityHubConfiguration",
      "securityhub:EnableOrganizationAdminAccount",
      "securityhub:DisableOrganizationAdminAccount",

      "guardduty:CreateDetector",
      "guardduty:GetDetector",
      "guardduty:DeleteDetector",
      "guardduty:ListOrganizationAdminAccounts",
      "guardduty:EnableOrganizationAdminAccount",
      "guardduty:DisableOrganizationAdminAccount",

      "macie2:EnableOrganizationAdminAccount",
      "macie2:ListOrganizationAdminAccounts",
      "macie2:DisableOrganizationAdminAccount"
    ]
    resources = ["*"]
  }
}
