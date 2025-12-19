<!-- BEGIN_TF_DOCS -->
## Requirements

The following requirements are needed by this module:

- terraform (>= 1.5.7)

- aws (>= 6.0.0)

## Providers

The following providers are used by this module:

- aws (>= 6.0.0)

## Modules

The following Modules are called:

### ntc\_cognito

Source: github.com/nuvibit-terraform-collection/terraform-aws-ntc-cognito-module

Version: 1.0.0

## Resources

The following resources are used by this module:

- [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) (data source)
- [aws_region.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) (data source)

## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

The following outputs are exported:

### account\_id

Description: The current account id

### default\_region

Description: The default region name
<!-- END_TF_DOCS -->