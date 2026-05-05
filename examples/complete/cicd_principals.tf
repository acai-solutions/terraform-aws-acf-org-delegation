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
# ¦ CREATE PROVISIONER
# ---------------------------------------------------------------------------------------------------------------------
module "create_provisioner" {
  source = "../../cicd-principals/terraform"

  iam_role_settings = {
    name = "ou_mgmt_cicd_provisioner"
    aws_trustee_arns = [
      "arn:${data.aws_partition.current.partition}:iam::${var.account_ids.org_mgmt}:root"
    ]
  }
  providers = {
    aws = aws.org_mgmt
  }
}

# Primary region provider, assuming the CI/CD provisioner role created above.
provider "aws" {
  region = var.aws_region
  alias  = "org_mgmt_primary"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}

# Secondary region provider - only relevant for AWS commercial (us-east-1).
# On non-commercial partitions (e.g. AWS ESC) us-east-1 does not exist, so we
# fall back to the primary region to keep the provider configurable; the
# consuming module instance is gated by `count` and will not be created.
provider "aws" {
  region = var.aws_partition == "aws" ? "us-east-1" : var.aws_region
  alias  = "org_mgmt_use1"
  assume_role {
    role_arn = module.create_provisioner.iam_role_arn
  }
}