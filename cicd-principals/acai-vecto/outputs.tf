# ACAI Cloud Foundation (ACF)
# Copyright (C) 2025 ACAI GmbH
# Licensed under AGPL v3
#
# This file is part of ACAI ACF.
# Visit https://www.acai.gmbh or https://docs.acai.gmbh for more information.
# 
# For full license text, see LICENSE file in repository root.
# For commercial licensing, contact: contact@acai.gmbh


output "cf_template_map" {
  value = {
    "org_delegation.yaml.tftpl" = replace(data.template_file.org_delegation.rendered, "$$$", "$$")
  }
}
