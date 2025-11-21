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
# ¦ REQUIREMENTS
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


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "current" {}

locals {
  resource_tags = var.aws_organizations_resource_policy != null ? merge(
    var.aws_organizations_resource_policy.resource_tags,
    {
      "module_provider" = "ACAI GmbH",
      "module_name"     = "terraform-aws-acf-org-delegation",
      "module_source"   = "github.com/acai-consulting/terraform-aws-acf-org-delegation",
      "module_version"  = /*inject_version_start*/ "1.1.0" /*inject_version_end*/
    }
  ) : null

  is_use1 = data.aws_region.current.name == "us-east-1"
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ AWS ORGANIZATIONS RESOURCE POLICY
# ---------------------------------------------------------------------------------------------------------------------
# See: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies.html
# This is a global resource - marke sure you specify it only once
resource "aws_organizations_resource_policy" "aws_organizations_resource_policy" {
  count = var.aws_organizations_resource_policy == null ? 0 : 1

  content = var.aws_organizations_resource_policy.content_as_json
  tags    = local.resource_tags
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATIONS
# ---------------------------------------------------------------------------------------------------------------------
# See: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html?icmpid=docs_orgs_console
locals {
  skipped_delegations = [
    "stacksets.cloudformation.amazonaws.com",
    "fms.amazonaws.com"
  ]
  common_delegations = [for delegation in var.delegations :
    {
      service_principal = delegation.service_principal,
      target_account_id = delegation.target_account_id
    } if !contains(local.skipped_delegations, delegation.service_principal) && var.primary_aws_region == true
  ]
}

resource "aws_organizations_delegated_administrator" "delegations" {
  for_each = { for del in local.common_delegations : "${del.target_account_id}/${del.service_principal}" => del }

  account_id        = each.value.target_account_id
  service_principal = each.value.service_principal
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - auditmanager.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  auditmanager_delegation       = contains([for d in var.delegations : d.service_principal], "auditmanager.amazonaws.com")
  auditmanager_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "auditmanager.amazonaws.com"][0], null)
}

resource "aws_auditmanager_organization_admin_account_registration" "auditmanager" {
  count = local.auditmanager_delegation ? 1 : 0

  admin_account_id = local.auditmanager_admin_account_id
  depends_on       = [aws_organizations_delegated_administrator.delegations]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - config.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  config_delegation         = contains([for d in var.delegations : d.service_principal], "config.amazonaws.com")
  config_admin_account_id   = try([for d in var.delegations : d.target_account_id if d.service_principal == "config.amazonaws.com"][0], null)
  config_aggregation_region = try([for d in var.delegations : d.aggregation_region if d.service_principal == "config.amazonaws.com"][0], null)
}

resource "aws_config_aggregate_authorization" "config_delegation" {
  count = local.config_delegation ? 1 : 0

  account_id            = local.config_admin_account_id
  authorized_aws_region = local.config_aggregation_region
  depends_on            = [aws_organizations_delegated_administrator.delegations]
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - securityhub.amazonaws.com
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account
# https://docs.aws.amazon.com/securityhub/latest/userguide/central-configuration-intro.html
# ---------------------------------------------------------------------------------------------------------------------
locals {
  securityhub_delegation       = contains([for d in var.delegations : d.service_principal], "securityhub.amazonaws.com")
  securityhub_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "securityhub.amazonaws.com"][0], null)
}

resource "aws_securityhub_account" "securityhub" {
  count = local.securityhub_delegation ? 1 : 0

  enable_default_standards = false
  lifecycle {
    ignore_changes = [
      control_finding_generator # https://github.com/hashicorp/terraform-provider-aws/issues/30980
    ]
  }
  depends_on = [aws_organizations_delegated_administrator.delegations]
}

resource "aws_securityhub_organization_admin_account" "securityhub" {
  count = local.securityhub_delegation ? 1 : 0

  admin_account_id = local.securityhub_admin_account_id
  depends_on       = [aws_securityhub_account.securityhub[0]]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - guardduty.amazonaws.com
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account
# ---------------------------------------------------------------------------------------------------------------------
locals {
  guardduty_delegation       = contains([for d in var.delegations : d.service_principal], "guardduty.amazonaws.com")
  guardduty_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "guardduty.amazonaws.com"][0], null)
}

resource "aws_guardduty_detector" "guardduty" {
  #checkov:skip=CKV2_AWS_3
  count      = local.guardduty_delegation ? 1 : 0
  depends_on = [aws_organizations_delegated_administrator.delegations]
}

resource "aws_guardduty_organization_admin_account" "guardduty" {
  count = local.guardduty_delegation && var.primary_aws_region ? 1 : 0

  admin_account_id = local.guardduty_admin_account_id
  depends_on       = [aws_guardduty_detector.guardduty]
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - detective.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  detective_delegation       = contains([for d in var.delegations : d.service_principal], "detective.amazonaws.com")
  detective_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "detective.amazonaws.com"][0], null)
}

resource "aws_detective_organization_admin_account" "detective" {
  count = local.detective_delegation ? 1 : 0

  account_id = local.detective_admin_account_id
  depends_on = [aws_organizations_delegated_administrator.delegations]
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - inspector2.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  inspector_delegation       = contains([for d in var.delegations : d.service_principal], "inspector2.amazonaws.com")
  inspector_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "inspector2.amazonaws.com"][0], null)
}

resource "aws_inspector2_delegated_admin_account" "inspector" {
  count = local.inspector_delegation ? 1 : 0

  account_id = local.inspector_admin_account_id
}


# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - fms.amazonaws.com
# once delegated, it can only be revoked from the delegated account
# ---------------------------------------------------------------------------------------------------------------------
locals {
  fms_delegation       = contains([for d in var.delegations : d.service_principal], "fms.amazonaws.com")
  fms_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "fms.amazonaws.com"][0], null)
}

resource "aws_fms_admin_account" "fms" {
  count = local.fms_delegation ? 1 : 0

  account_id = local.fms_admin_account_id
  lifecycle {
    precondition {
      condition     = local.is_use1
      error_message = "FMS can only be delegated in 'us-east-1'. Current provider region is '${data.aws_region.current.name}'."
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - macie.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  macie_delegation       = contains([for d in var.delegations : d.service_principal], "macie.amazonaws.com")
  macie_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "macie.amazonaws.com"][0], null)
}

resource "aws_macie2_account" "macie" {
  count      = local.macie_delegation ? 1 : 0
  depends_on = [aws_organizations_delegated_administrator.delegations]
}

resource "aws_macie2_organization_admin_account" "macie" {
  count = local.macie_delegation ? 1 : 0

  admin_account_id = local.macie_admin_account_id
  depends_on = [
    aws_macie2_account.macie
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - ipam.amazonaws.com
# ---------------------------------------------------------------------------------------------------------------------
locals {
  ipam_delegation       = contains([for d in var.delegations : d.service_principal], "ipam.amazonaws.com")
  ipam_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "ipam.amazonaws.com"][0], null)
}

resource "aws_vpc_ipam_organization_admin_account" "ipam" {
  count = local.ipam_delegation ? 1 : 0

  delegated_admin_account_id = local.ipam_admin_account_id
  depends_on                 = [aws_organizations_delegated_administrator.delegations]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DELEGATION - cloudtrail.amazonaws.com
# CloudTrail Lake delegated administrator allows centralized management of CloudTrail across the organization
# The delegated admin can enable organization-wide event collection without individual member account setup
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudtrail_organization_delegated_admin_account
# ---------------------------------------------------------------------------------------------------------------------
locals {
  cloudtrail_delegation       = contains([for d in var.delegations : d.service_principal], "cloudtrail.amazonaws.com")
  cloudtrail_admin_account_id = try([for d in var.delegations : d.target_account_id if d.service_principal == "cloudtrail.amazonaws.com"][0], null)
}

resource "aws_cloudtrail_organization_delegated_admin_account" "cloudtrail" {
  count = local.cloudtrail_delegation ? 1 : 0

  account_id = local.cloudtrail_admin_account_id
  depends_on = [aws_organizations_delegated_administrator.delegations]
}
