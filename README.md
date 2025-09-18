# terraform-aws-acf-ou-mgmt Terraform module

<!-- LOGO -->
<a href="https://acai.gmbh">    
  <img src="https://github.com/acai-solutions/acai.public/raw/main/logo/logo_github_readme.png" alt="acai logo" title="ACAI" align="right" height="75" />
</a>

<!-- SHIELDS -->
[![Maintained by acai.gmbh][acai-shield]][acai-url]
[![documentation][acai-docs-shield]][acai-docs-url]  
![module-version-shield]
![terraform-version-shield]  
![trivy-shield]
![checkov-shield]

<!-- BEGIN_ACAI_DOCS -->

<!-- DESCRIPTION -->
[Terraform][terraform-url] module to manage AWS Organization delegation.

<!-- FEATURES -->
## Features

``` hcl
locals {
  primary_aws_region = "eu-central-1"
  default_regions    = ["eu-central-1", "us-east-2"]
  delegations = [
    {
      regions           = ["us-east-1"]
      service_principal = "cloudtrail.amazonaws.com"
      target_account_id = "992382728088" # core_security
    },
    {
      regions           = local.default_regions
      service_principal = "guardduty.amazonaws.com"
      target_account_id = "992382728088" # core_security      
    },
    {
      regions           = local.default_regions
      service_principal = "securityhub.amazonaws.com"
      target_account_id = "992382728088" # core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "backup.amazonaws.com"
      target_account_id = "992382728088" # core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
      target_account_id = "992382728088" # core_security
    },
    {
      regions           = [local.primary_aws_region]
      service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
      target_account_id = "590183833356" # core_logging
    }
  ]
}

module "preprocess_data" {
  source = "../../modules/preprocess-data"

  primary_aws_region = local.primary_aws_region
  delegations        = local.delegations
}

module "example_euc1" {
  source = "../../"

  primary_aws_region = module.preprocess_data.is_primary_region["eu-central-1"]
  delegations        = module.preprocess_data.delegations_by_region["eu-central-1"]
  providers = {
    aws = aws.org_mgmt_euc1
  }
  depends_on = [module.create_provisioner]
}


module "example_use1" {
  source = "../../"

  primary_aws_region = module.preprocess_data.is_primary_region["us-east-1"]
  delegations        = module.preprocess_data.delegations_by_region["us-east-1"]
  providers = {
    aws = aws.org_mgmt_use1
  }
  depends_on = [
    module.create_provisioner,
    module.example_euc1
  ]
}

module "example_use2" {
  source = "../../"

  primary_aws_region = module.preprocess_data.is_primary_region["us-east-2"]
  delegations        = module.preprocess_data.delegations_by_region["us-east-2"]
  providers = {
    aws = aws.org_mgmt_use2
  }
  depends_on = [
    module.create_provisioner,
    module.example_euc1
  ]
}
```
<!-- END_ACAI_DOCS -->

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.10 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.30 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.30 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_auditmanager_organization_admin_account_registration.auditmanager](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/auditmanager_organization_admin_account_registration) | resource |
| [aws_config_aggregate_authorization.config_delegation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/config_aggregate_authorization) | resource |
| [aws_detective_organization_admin_account.detective](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/detective_organization_admin_account) | resource |
| [aws_fms_admin_account.fms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fms_admin_account) | resource |
| [aws_guardduty_detector.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_guardduty_organization_admin_account.guardduty](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_organization_admin_account) | resource |
| [aws_inspector2_delegated_admin_account.inspector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/inspector2_delegated_admin_account) | resource |
| [aws_macie2_account.macie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_account) | resource |
| [aws_macie2_organization_admin_account.macie](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/macie2_organization_admin_account) | resource |
| [aws_organizations_delegated_administrator.delegations](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_delegated_administrator) | resource |
| [aws_organizations_resource_policy.aws_organizations_resource_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_resource_policy) | resource |
| [aws_securityhub_account.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_account) | resource |
| [aws_securityhub_organization_admin_account.securityhub](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/securityhub_organization_admin_account) | resource |
| [aws_vpc_ipam_organization_admin_account.ipam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipam_organization_admin_account) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_organizations_resource_policy"></a> [aws\_organizations\_resource\_policy](#input\_aws\_organizations\_resource\_policy) | JSON of the AWS Organizations Delegation. Ensure this is only specified in one instance of this module | <pre>object({<br/>    content_as_json = string<br/>    resource_tags   = optional(map(string))<br/>  })</pre> | `null` | no |
| <a name="input_delegations"></a> [delegations](#input\_delegations) | List of delegations specifying the target account ID and service principal for AWS Organizations Delegated Administrators. | <pre>list(object({<br/>    service_principal : string # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html<br/>    target_account_id : string<br/>    aggregation_region : optional(string)<br/>    additional_settings = optional(map(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_primary_aws_region"></a> [primary\_aws\_region](#input\_primary\_aws\_region) | Explicitly decide if this is the primary AWS Regin. May only be done for one region. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_delegations"></a> [delegations](#output\_delegations) | List of AWS Organizations Delegated Administrators created. |
| <a name="output_resource_tags"></a> [resource\_tags](#output\_resource\_tags) | resource\_tags |
<!-- END_TF_DOCS -->

<!-- AUTHORS -->
## Authors

This module is maintained by [ACAI GmbH][acai-url].

<!-- LICENSE -->
## License

See [LICENSE][license-url] for full details.

<!-- MARKDOWN LINKS & IMAGES -->
[acai-shield]: https://img.shields.io/badge/maintained_by-acai.gmbh-CB224B?style=flat
[acai-docs-shield]: https://img.shields.io/badge/documentation-docs.acai.gmbh-CB224B?style=flat
[acai-url]: https://acai.gmbh
[acai-docs-url]: https://docs.acai.gmbh
[module-version-shield]: https://img.shields.io/badge/module_version-1.1.0-CB224B?style=flat
[module-release-url]: https://github.com/acai-solutions/terraform-aws-acf-org-delegation/releases
[terraform-version-shield]: https://img.shields.io/badge/tf-%3E%3D1.3.10-blue.svg?style=flat&color=blueviolet
[trivy-shield]: https://img.shields.io/badge/trivy-passed-green
[checkov-shield]: https://img.shields.io/badge/checkov-passed-green
[license-url]: https://github.com/acai-solutions/terraform-aws-acf-org-delegation/tree/main/LICENSE.md
[terraform-url]: https://www.terraform.io
