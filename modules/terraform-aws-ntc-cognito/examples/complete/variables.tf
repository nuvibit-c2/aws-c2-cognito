variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-central-1"
}

variable "user_pool_name" {
  description = "Name of the Cognito user pool"
  type        = string
  default     = "example-user-pool"
}

variable "domain_name" {
  description = "Cognito domain name (will be prefixed to .auth.region.amazoncognito.com)"
  type        = string
  default     = "example-app-auth"
}

variable "certificate_arn" {
  description = "ACM certificate ARN for custom domain (optional)"
  type        = string
  default     = null
}

variable "saml_metadata_url" {
  description = "SAML metadata URL for the identity provider (e.g., EntraID federation metadata URL)"
  type        = string
  default     = "https://login.microsoftonline.com/YOUR-TENANT-ID/federationmetadata/2007-06/federationmetadata.xml"
}

variable "app_callback_urls" {
  description = "List of callback URLs for the OAuth 2.0 app client"
  type        = list(string)
  default = [
    "https://example.com/callback",
    "http://localhost:3000/callback" # For local development
  ]
}

variable "accessing_account_id" {
  description = "AWS account ID that will access M2M client secrets (defaults to current account)"
  type        = string
  default     = null
}
