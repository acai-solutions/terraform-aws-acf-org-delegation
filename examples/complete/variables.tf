# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
#
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "account_ids" {
  type = object({
    org_mgmt      = string
    core_logging  = string
    core_security = string
    core_backup   = string
    workload      = string
  })
  description = "Account IDs for the different AWS accounts."
}

variable "aws_region" {
  type        = string
  description = "AWS region to use for all providers."
  default     = "eu-central-1"
}

variable "aws_partition" {
  type        = string
  description = "AWS partition to use for all providers."
  default     = "aws"
}

variable "aws_endpoint_domain" {
  type        = string
  description = "AWS endpoint domain to use for all providers (e.g. 'amazonaws.com' or 'amazonaws.com.cn')."
  default     = "amazonaws.com"
}

variable "iam_role_name" {
  type        = string
  description = "IAM role name to assume in each account."
  default     = "OrganizationAccountAccessRole"
}