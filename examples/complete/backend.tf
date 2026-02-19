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
# ¦ BACKEND
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = var.tf_state_bucket.s3_bucket_name
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.tf_state_bucket.dynamodb_table_name
    encrypt        = true
  }
}
