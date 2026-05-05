# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


variable "preprocessed_data" {
  description = "Preprocessed delegation data from the preprocess-data submodule, including the primary AWS region, the current AWS region this module instance targets, and the list of delegations for the current region."
  type = object({
    primary_aws_region = string
    current_aws_region = string
    delegations = list(object({
      service_principal   = string # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
      target_account_id   = string
      aggregation_region  = optional(string)
      additional_settings = optional(map(string))
    }))
  })

  validation {
    condition     = alltrue([for d in var.preprocessed_data.delegations : can(regex("^\\d{12}$", d.target_account_id))])
    error_message = "Each 'target_account_id' must be a 12-digit AWS account ID."
  }
}

variable "aws_organizations_resource_policy" {
  description = "JSON of the AWS Organizations Delegation. Ensure this is only specified in one instance of this module"
  type = object({
    content_as_json = string
    resource_tags   = optional(map(string))
  })
  default = null
}