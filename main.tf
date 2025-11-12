# ---------------------------------------------------------------------------------------------------------------------
# ¦ PROVIDER
# ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "euc1"
  region = "eu-central-1"
  default_tags {
    tags = local.default_tags
  }
}

provider "aws" {
  alias  = "euc2"
  region = "eu-central-2"
  default_tags {
    tags = local.default_tags
  }
}

# provider for us-east-1 region is sometimes required for specific features or services
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
  default_tags {
    tags = local.default_tags
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.5.7"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = []
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA
# ---------------------------------------------------------------------------------------------------------------------
data "aws_region" "default" {}
data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  default_tags = {
    ManagedBy = "OpenTofu"
    # ProvisionedBy = "aws-xx-yyy"
  }
}
# ---------------------------------------------------------------------------------------------------------------------
# ¦ COGNITO MODULE
# ---------------------------------------------------------------------------------------------------------------------
module "cognito" {
  source = "./modules/terraform-aws-ntc-cognito"

  user_pools = [
    {
      name = "c2-user-pool"

      domain = {
        name = "c2-user-pool"
      }

      idps = [
        {
          provider_name = "entra-id"
          provider_type = "SAML"
          provider_details = {
            MetadataURL             = "https://login.microsoftonline.com/2e952181-6766-456a-b998-3bd7c1327084/FederationMetadata/2007-06/FederationMetadata.xml" # TODO: Add app specific metadata URL here
            EncryptedResponses      = "false"
            RequestSigningAlgorithm = "rsa-sha256"
          }
          attribute_mapping = {
            name        = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            given_name  = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
            family_name = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"

          }
        }
      ]

      groups = []
      users  = []
      app_clients = [
        {
          name           = "test-client"
          callback_urls  = ["https://oauth.pstmn.io/v1/callback"]
          supported_idps = ["entra-id"]
        }
      ]
      m2m_clients = [
        {
          name                          = "m2m-test-client"
          accessing_solution_account_id = data.aws_caller_identity.current.account_id
          custom_scope_name             = "api.read"
          custom_scope_description      = "Test M2M client for API read access"
        }
      ]
    }
  ]
}