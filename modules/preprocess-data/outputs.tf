# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "delegated_administrators" {
  description = "List of delegated admins."
  value       = local.delegated_administrators
}

output "delegations_by_region" {
  description = "List of delegations per region."
  value       = local.delegations_by_region
}

# https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html
output "aws_service_access_principals" {
  description = "Consolidated distinct list of aws_service_access_principals"
  value       = local.aws_service_access_principals
}

output "is_primary_region" {
  description = "is_primary_region"
  value       = local.is_primary_region
}

