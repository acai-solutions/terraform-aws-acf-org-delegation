<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_delegations"></a> [delegations](#input\_delegations) | List of delegations specifying the target account ID and service principal for AWS Organizations Delegated Administrators. | <pre>list(object({<br/>    regions : list(string)<br/>    service_principal : string # https://docs.aws.amazon.com/organizations/latest/userguide/orgs_integrate_services_list.html<br/>    target_account_id : string<br/>    aggregation_region : optional(string)<br/>    additional_settings = optional(map(string))<br/>  }))</pre> | `[]` | no |
| <a name="input_primary_aws_region"></a> [primary\_aws\_region](#input\_primary\_aws\_region) | Name of the primary AWS Region. | `string` | `"us-east-1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_service_access_principals"></a> [aws\_service\_access\_principals](#output\_aws\_service\_access\_principals) | Consolidated distinct list of aws\_service\_access\_principals |
| <a name="output_delegated_administrators"></a> [delegated\_administrators](#output\_delegated\_administrators) | List of delegated admins. |
| <a name="output_delegations_by_region"></a> [delegations\_by\_region](#output\_delegations\_by\_region) | List of delegations per region. |
| <a name="output_is_primary_region"></a> [is\_primary\_region](#output\_is\_primary\_region) | is\_primary\_region |
<!-- END_TF_DOCS -->