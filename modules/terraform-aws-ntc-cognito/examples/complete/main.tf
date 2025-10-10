# ---------------------------------------------------------------------------------------------------------------------
# Example - AWS Cognito User Pool Module
# ---------------------------------------------------------------------------------------------------------------------
# This example demonstrates basic usage of the terraform-aws-cognito module with:
# - A single user pool
# - SAML identity provider (EntraID/Azure AD)
# - OAuth 2.0 app client
# - M2M client for API access
# - Custom domain
# ---------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Example     = "terraform-aws-cognito-simple"
      ManagedBy   = "Terraform"
      Environment = "example"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Use the Cognito module to create a user pool with SAML IdP
# ---------------------------------------------------------------------------------------------------------------------

module "cognito" {
  source = "../.."

  user_pools = [
    {
      name = var.user_pool_name

      # Custom domain configuration (optional)
      domain = {
        name            = var.domain_name
        certificate_arn = var.certificate_arn # Optional: for custom domains
      }

      # SAML Identity Provider (e.g., EntraID/Azure AD)
      idps = [
        {
          provider_name = "EntraID"
          provider_type = "SAML"
          provider_details = {
            MetadataURL = var.saml_metadata_url
          }
          attribute_mapping = {
            email    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            username = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            name     = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
          }
          idp_identifiers = []
        }
      ]

      # Groups for authorization (optional but recommended)
      groups = [
        {
          name        = "administrators"
          description = "Administrator users with full access"
          precedence  = 1
        },
        {
          name        = "users"
          description = "Regular users with standard access"
          precedence  = 10
        },
        {
          name        = "readonly"
          description = "Read-only access users"
          precedence  = 20
        }
      ]

      # No manual users when using IdP authentication
      users = []

      # OAuth 2.0 App Client for web applications
      app_clients = [
        {
          name           = "web-app-client"
          callback_urls  = var.app_callback_urls
          supported_idps = ["EntraID"]
        }
      ]

      # M2M Client for API-to-API authentication
      m2m_clients = [
        {
          name                          = "api-service-client"
          accessing_solution_account_id = var.accessing_account_id
          custom_scope_name             = "api.access"
          custom_scope_description      = "Full API access for service-to-service communication"
        }
      ]
    }
  ]
}