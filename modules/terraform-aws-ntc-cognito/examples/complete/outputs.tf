# ---------------------------------------------------------------------------------------------------------------------
# User Pool Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "user_pool_id" {
  description = "ID of the created Cognito user pool"
  value       = module.cognito.user_pool_ids[var.user_pool_name]
}

output "user_pool_arn" {
  description = "ARN of the created Cognito user pool"
  value       = module.cognito.user_pool_arns[var.user_pool_name]
}

output "user_pool_domain" {
  description = "Domain name of the Cognito user pool"
  value       = module.cognito.user_pool_domains[var.user_pool_name]
}

output "user_pool_endpoint" {
  description = "Endpoint URL of the Cognito user pool"
  value       = "https://${module.cognito.user_pool_domains[var.user_pool_name]}.auth.${var.aws_region}.amazoncognito.com"
}

# ---------------------------------------------------------------------------------------------------------------------
# App Client Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "app_client_id" {
  description = "Client ID for the web application"
  value       = module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].client_id
}

output "app_client_authorize_endpoint" {
  description = "OAuth 2.0 authorization endpoint"
  value       = module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].authorize_endpoint
}

output "app_client_token_endpoint" {
  description = "OAuth 2.0 token endpoint"
  value       = module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].token_endpoint
}

output "app_client_userinfo_endpoint" {
  description = "OAuth 2.0 user info endpoint"
  value       = module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].userinfo_endpoint
}

# ---------------------------------------------------------------------------------------------------------------------
# M2M Client Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "m2m_client_token_endpoint" {
  description = "Token endpoint for M2M authentication"
  value       = module.cognito.m2m_client_map_by_pool[var.user_pool_name]["api-service-client"].token_endpoint
}

output "m2m_secret_arn" {
  description = "ARN of the Secrets Manager secret containing M2M client credentials"
  value       = module.cognito.m2m_client_map_by_pool[var.user_pool_name]["api-service-client"].secret_arn
}

output "m2m_custom_scope" {
  description = "Custom scope identifier for M2M client"
  value       = module.cognito.m2m_client_map_by_pool[var.user_pool_name]["api-service-client"].custom_scope_identifier
}

# ---------------------------------------------------------------------------------------------------------------------
# Identity Provider Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "identity_providers" {
  description = "Map of configured identity providers"
  value       = module.cognito.identity_providers
}

# ---------------------------------------------------------------------------------------------------------------------
# Group Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "cognito_groups" {
  description = "Map of created Cognito groups"
  value       = module.cognito.cognito_groups
}

# ---------------------------------------------------------------------------------------------------------------------
# API Gateway Outputs
# ---------------------------------------------------------------------------------------------------------------------

output "api_gateway_id" {
  description = "ID of the example API Gateway"
  value       = aws_api_gateway_rest_api.example.id
}

output "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_api_gateway_rest_api.example.execution_arn
}

# ---------------------------------------------------------------------------------------------------------------------
# Complete Configuration Examples
# ---------------------------------------------------------------------------------------------------------------------

output "oauth_authorization_url_example" {
  description = "Example OAuth 2.0 authorization URL (replace {redirect_uri} with your callback URL)"
  value = format(
    "%s?client_id=%s&response_type=code&scope=email+openid+profile&redirect_uri={redirect_uri}",
    module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].authorize_endpoint,
    module.cognito.app_client_map_by_pool[var.user_pool_name]["web-app-client"].client_id
  )
}

output "m2m_authentication_command" {
  description = "Example curl command to retrieve M2M access token (requires client_secret from Secrets Manager)"
  value = format(
    "curl -X POST %s -H 'Content-Type: application/x-www-form-urlencoded' -d 'grant_type=client_credentials&client_id={client_id}&client_secret={client_secret}&scope=%s'",
    module.cognito.m2m_client_map_by_pool[var.user_pool_name]["api-service-client"].token_endpoint,
    module.cognito.m2m_client_map_by_pool[var.user_pool_name]["api-service-client"].custom_scope_identifier
  )
}

# ---------------------------------------------------------------------------------------------------------------------
# All Module Outputs (for reference)
# ---------------------------------------------------------------------------------------------------------------------

output "all_app_clients" {
  description = "All app client configurations organized by pool"
  value       = module.cognito.app_client_map_by_pool
  sensitive   = false
}

output "all_m2m_clients" {
  description = "All M2M client configurations organized by pool"
  value       = module.cognito.m2m_client_map_by_pool
  sensitive   = false
}
