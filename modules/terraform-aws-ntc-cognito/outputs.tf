output "app_client_map_by_pool" {
  description = "App client configuration details organized by user pool"
  value       = local.app_client_map_by_pool
}

output "m2m_client_map_by_pool" {
  description = "M2M client configuration details organized by user pool"
  value       = local.m2m_client_map_by_pool
}

output "m2m_secrets" {
  description = "Map of M2M client secrets in AWS Secrets Manager"
  value = {
    for client_name, secret in aws_secretsmanager_secret.m2m_secrets : client_name => {
      secret_arn  = secret.arn
      secret_name = secret.name
      kms_key_id  = secret.kms_key_id
    }
  }
}

output "user_pool_ids" {
  description = "Map of user pool names to user pool IDs"
  value       = { for pool_name, pool in aws_cognito_user_pool.user_pools : pool_name => pool.id }
}

output "user_pool_arns" {
  description = "Map of user pool names to user pool ARNs"
  value       = { for pool_name, pool in aws_cognito_user_pool.user_pools : pool_name => pool.arn }
}

output "user_pool_domains" {
  description = "Map of user pool names to user pool domain names"
  value       = { for pool_name, domain in aws_cognito_user_pool_domain.domains : pool_name => domain.domain }
}

output "identity_providers" {
  description = "Map of identity provider keys to provider names"
  value       = { for key, idp in aws_cognito_identity_provider.idps : key => idp.provider_name }
}

output "cognito_groups" {
  description = "Map of group keys to group details"
  value = {
    for key, group in aws_cognito_user_group.groups : key => {
      name           = group.name
      user_pool_name = local.all_groups[key].user_pool_name
      description    = group.description
      precedence     = group.precedence
    }
  }
}

output "cognito_users" {
  description = "Map of user keys to user details (excluding sensitive data)"
  value = {
    for key, user in aws_cognito_user.users : key => {
      username       = user.username
      user_pool_name = local.users[key].user_pool_name
      email          = local.users[key].email
      groups         = local.users[key].groups
    }
  }
}