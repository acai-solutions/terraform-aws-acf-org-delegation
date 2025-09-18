# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "delegations" {
  description = "List of AWS Organizations Delegated Administrators created."
  value = [for del in aws_organizations_delegated_administrator.delegations : {
    account_id        = del.account_id
    service_principal = del.service_principal
  }]
}

output "resource_tags" {
  description = "resource_tags"
  value       = local.resource_tags
}

