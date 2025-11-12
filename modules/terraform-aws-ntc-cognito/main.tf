# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIREMENTS
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.98.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "2.7.1"
    }
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ DATA SOURCES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ LOCALS
# ---------------------------------------------------------------------------------------------------------------------
locals {
  // Helper function to parse time string (e.g., "30d" -> {value: 30, unit: "days"})
  parse_time_string = {
    unit_map = {
      "s" = "seconds"
      "m" = "minutes"
      "h" = "hours"
      "d" = "days"
    }
  }

  // User pool domains for use in client mappings
  user_pool_domains = {
    for pool_name, domain in aws_cognito_user_pool_domain.domains :
    pool_name => format("https://%s.auth.%s.amazoncognito.com", domain.domain, data.aws_region.current.name)
  }

  // Flatten app_clients from nested structure
  app_clients = {
    for item in flatten([
      for pool in var.user_pools : [
        for client in pool.app_clients : {
          key            = "${pool.name}_${client.name}"
          name           = client.name
          user_pool_name = pool.name
          callback_urls  = client.callback_urls
          supported_idps = client.supported_idps
          // Parse auth_session_validity (e.g., "3m" -> 3 minutes, only accepts minutes)
          auth_session_validity = tonumber(regex("^([0-9]+)m$", client.auth_session_validity)[0])
          // Parse token validity values (supports s, m, h, d)
          refresh_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.refresh_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.refresh_token_validity)[0])
          }
          access_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.access_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.access_token_validity)[0])
          }
          id_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.id_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.id_token_validity)[0])
          }
        }
      ]
    ]) : item.key => item
  }

  // Manual groups from variable
  manual_groups = {
    for item in flatten([
      for pool in var.user_pools : [
        for group in pool.groups : {
          key            = "${pool.name}_${group.name}"
          group_name     = group.name
          user_pool_name = pool.name
          description    = coalesce(group.description, "Managed by Terraform")
          precedence     = group.precedence
        }
      ]
    ]) : item.key => item
  }

  // All groups come from manual configuration only
  all_groups = local.manual_groups

  // Flatten users from nested structure
  users = {
    for item in flatten([
      for pool in var.user_pools : [
        for user in pool.users : {
          key            = "${pool.name}_${user.username}"
          username       = user.username
          email          = user.email
          user_pool_name = pool.name
          groups         = user.groups
          attributes     = user.attributes
        }
      ]
    ]) : item.key => item
  }

  // App client map with client info
  app_client_map = {
    for client_id, client in local.app_clients :
    client_id => {
      name               = client.name
      user_pool_name     = client.user_pool_name
      user_pool_id       = aws_cognito_user_pool_client.app_clients[client_id].user_pool_id
      user_pool_arn      = aws_cognito_user_pool.user_pools[client.user_pool_name].arn
      client_id          = aws_cognito_user_pool_client.app_clients[client_id].id
      authorize_endpoint = format("%s/oauth2/authorize", local.user_pool_domains[client.user_pool_name])
      token_endpoint     = format("%s/oauth2/token", local.user_pool_domains[client.user_pool_name])
      userinfo_endpoint  = format("%s/oauth2/userInfo", local.user_pool_domains[client.user_pool_name])
    }
  }

  // Create a map of user_pool_name to app clients for output compatibility
  app_client_map_by_pool = {
    for pool in var.user_pools :
    pool.name => {
      for client_id, client in local.app_client_map :
      client.name => client if client.user_pool_name == pool.name
    }
  }

  // Flatten m2m_clients from nested structure
  m2m_clients = {
    for item in flatten([
      for pool in var.user_pools : [
        for client in pool.m2m_clients : {
          key                           = "${pool.name}_${client.name}"
          name                          = client.name
          user_pool_name                = pool.name
          accessing_solution_account_id = client.accessing_solution_account_id
          custom_scope_name             = client.custom_scope_name
          custom_scope_description      = client.custom_scope_description
          // Parse auth_session_validity (e.g., "3m" -> 3 minutes, only accepts minutes)
          auth_session_validity = tonumber(regex("^([0-9]+)m$", client.auth_session_validity)[0])
          // Parse token validity values (supports s, m, h, d)
          refresh_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.refresh_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.refresh_token_validity)[0])
          }
          access_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.access_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.access_token_validity)[0])
          }
          id_token_validity = {
            value = tonumber(regex("^([0-9]+)[smhd]$", client.id_token_validity)[0])
            unit  = lookup(local.parse_time_string.unit_map, regex("^[0-9]+([smhd])$", client.id_token_validity)[0])
          }
        }
      ]
    ]) : item.key => item
  }

  // M2M client map
  m2m_client_map = {
    for client_name, client in local.m2m_clients :
    client_name => {
      name                          = client.name
      user_pool_name                = client.user_pool_name
      user_pool_id                  = aws_cognito_user_pool_client.m2m_clients[client_name].user_pool_id
      user_pool_arn                 = aws_cognito_user_pool.user_pools[client.user_pool_name].arn
      authorize_endpoint            = format("%s/oauth2/authorize", local.user_pool_domains[client.user_pool_name])
      token_endpoint                = format("%s/oauth2/token", local.user_pool_domains[client.user_pool_name])
      secret_arn                    = aws_secretsmanager_secret.m2m_secrets[client_name].arn
      custom_scope_identifier       = aws_cognito_resource_server.resource_servers[client_name].scope_identifiers[0]
      accessing_solution_account_id = client.accessing_solution_account_id
    }
  }

  // Create a map of user_pool_name to m2m clients for output compatibility
  m2m_client_map_by_pool = {
    for pool in var.user_pools :
    pool.name => {
      for client_name, client in local.m2m_client_map :
      client_name => client if client.user_pool_name == pool.name
    }
  }

  // KMS policy principal ARNs for accessing solution accounts
  // Only contains entries for user pools that have M2M clients with external accessing accounts
  m2m_accessing_account_principals = {
    for pool in var.user_pools :
    pool.name => [
      for account_id in distinct([for k, v in local.m2m_clients : v.accessing_solution_account_id if v.user_pool_name == pool.name]) :
      format("arn:aws:iam::%s:root", account_id)
    ]
    if length([for k, v in local.m2m_clients : v.accessing_solution_account_id if v.user_pool_name == pool.name]) > 0
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ USER POOLS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user_pool" "user_pools" {
  for_each = { for pool in var.user_pools : pool.name => pool }

  name                = each.key
  deletion_protection = "INACTIVE"

  account_recovery_setting {
    recovery_mechanism {
      name     = "admin_only"
      priority = 1
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "AUDIT" # TODO: make configurable in a "plus feature block"
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }

  dynamic "schema" {
    for_each = each.value.custom_attributes
    content {
      attribute_data_type      = schema.value.attribute_data_type
      name                     = schema.value.name
      developer_only_attribute = schema.value.developer_only_attribute
      mutable                  = schema.value.mutable
      required                 = schema.value.required

      dynamic "string_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "String" && schema.value.string_attribute_constraints != null ? [schema.value.string_attribute_constraints] : []
        content {
          min_length = string_attribute_constraints.value.min_length
          max_length = string_attribute_constraints.value.max_length
        }
      }

      dynamic "number_attribute_constraints" {
        for_each = schema.value.attribute_data_type == "Number" && schema.value.number_attribute_constraints != null ? [schema.value.number_attribute_constraints] : []
        content {
          min_value = number_attribute_constraints.value.min_value
          max_value = number_attribute_constraints.value.max_value
        }
      }
    }
  }

}

resource "aws_cognito_user_pool_domain" "domains" {
  for_each        = { for pool in var.user_pools : pool.name => pool }
  domain          = each.value.domain.name
  certificate_arn = try(each.value.domain.certificate_arn, null)
  user_pool_id    = aws_cognito_user_pool.user_pools[each.key].id
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ IDENTITY PROVIDERS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_identity_provider" "idps" {
  for_each = {
    for idp in flatten([
      for pool_idx, pool in var.user_pools : [
        for idp_idx, idp in pool.idps : {
          pool_name         = pool.name
          provider_name     = idp.provider_name
          provider_type     = idp.provider_type
          provider_details  = idp.provider_details
          attribute_mapping = idp.attribute_mapping
          idp_identifiers   = idp.idp_identifiers
          key               = "${pool.name}_${idp.provider_name}"
        }
      ]
    ]) : idp.key => idp
  }

  user_pool_id      = aws_cognito_user_pool.user_pools[each.value.pool_name].id
  provider_name     = each.value.provider_name
  provider_type     = each.value.provider_type
  provider_details  = each.value.provider_details
  attribute_mapping = each.value.attribute_mapping
  idp_identifiers   = each.value.idp_identifiers

  lifecycle {
    ignore_changes = [provider_details["ActiveEncryptionCertificate"]]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ APP CLIENTS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user_pool_client" "app_clients" {
  for_each = local.app_clients

  name                                 = each.value.name
  user_pool_id                         = aws_cognito_user_pool.user_pools[each.value.user_pool_name].id
  allowed_oauth_scopes                 = ["email", "openid", "phone", "profile"]
  explicit_auth_flows                  = ["ALLOW_REFRESH_TOKEN_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_USER_PASSWORD_AUTH"]
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  enable_token_revocation              = true
  prevent_user_existence_errors        = "ENABLED"
  callback_urls                        = each.value.callback_urls
  auth_session_validity                = each.value.auth_session_validity

  # Use the supported_idps list from the client configuration
  supported_identity_providers = each.value.supported_idps

  token_validity_units {
    access_token  = each.value.access_token_validity.unit
    id_token      = each.value.id_token_validity.unit
    refresh_token = each.value.refresh_token_validity.unit
  }

  access_token_validity  = each.value.access_token_validity.value
  id_token_validity      = each.value.id_token_validity.value
  refresh_token_validity = each.value.refresh_token_validity.value
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COGNITO GROUPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user_group" "groups" {
  for_each = local.all_groups

  name         = each.value.group_name
  user_pool_id = aws_cognito_user_pool.user_pools[each.value.user_pool_name].id
  description  = each.value.description
  precedence   = each.value.precedence
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ COGNITO USERS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user" "users" {
  for_each = local.users

  user_pool_id = aws_cognito_user_pool.user_pools[each.value.user_pool_name].id
  username     = each.value.username

  attributes = merge(
    {
      email          = each.value.email
      email_verified = true
    },
    each.value.attributes
  )

  # Prevent Terraform from trying to manage the password
  lifecycle {
    ignore_changes = [password]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ USER GROUP MEMBERSHIPS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_user_in_group" "user_group_memberships" {
  for_each = {
    for item in flatten([
      for user_key, user in local.users : [
        for group_name in user.groups : {
          key            = "${user_key}_${group_name}"
          user_pool_id   = aws_cognito_user_pool.user_pools[user.user_pool_name].id
          username       = user.username
          group_name     = group_name
          user_pool_name = user.user_pool_name
        }
      ]
    ]) : item.key => item
  }

  user_pool_id = each.value.user_pool_id
  group_name   = each.value.group_name
  username     = each.value.username

  depends_on = [
    aws_cognito_user.users,
    aws_cognito_user_group.groups
  ]
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ M2M CLIENTS AND RESOURCE SERVERS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_cognito_resource_server" "resource_servers" {
  for_each = local.m2m_clients

  user_pool_id = aws_cognito_user_pool.user_pools[each.value.user_pool_name].id
  identifier   = format("%s/%s", each.value.user_pool_name, each.value.name)
  name         = each.value.name

  scope {
    scope_name        = each.value.custom_scope_name
    scope_description = each.value.custom_scope_description
  }
}

resource "aws_cognito_user_pool_client" "m2m_clients" {
  for_each = local.m2m_clients

  name                                 = each.value.name
  user_pool_id                         = aws_cognito_user_pool.user_pools[each.value.user_pool_name].id
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = aws_cognito_resource_server.resource_servers[each.key].scope_identifiers
  allowed_oauth_flows_user_pool_client = true
  enable_token_revocation              = true
  generate_secret                      = true
  prevent_user_existence_errors        = "ENABLED"
  auth_session_validity                = each.value.auth_session_validity

  token_validity_units {
    access_token  = each.value.access_token_validity.unit
    id_token      = each.value.id_token_validity.unit
    refresh_token = each.value.refresh_token_validity.unit
  }

  access_token_validity  = each.value.access_token_validity.value
  id_token_validity      = each.value.id_token_validity.value
  refresh_token_validity = each.value.refresh_token_validity.value
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ M2M CLIENT SECRETS
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "m2m_secrets" {
  for_each = {
    for client_key, client in aws_cognito_user_pool_client.m2m_clients :
    client_key => {
      name        = "${local.m2m_clients[client_key].user_pool_name}_${client.name}"
      description = "Secret for m2m client ${client.name} in pool ${local.m2m_clients[client_key].user_pool_name}"
    }
  }

  name        = each.value.name
  description = each.value.description
  kms_key_id  = aws_kms_key.secret_kms_key[local.m2m_clients[each.key].user_pool_name].arn
}

resource "aws_secretsmanager_secret_version" "m2m_secret_versions" {
  for_each = {
    for client_key, client in aws_cognito_user_pool_client.m2m_clients :
    client_key => {
      secret_id     = aws_secretsmanager_secret.m2m_secrets[client_key].id
      client_id     = client.id
      client_secret = client.client_secret
    }
  }

  secret_id = each.value.secret_id
  secret_string = jsonencode({
    client_id     = each.value.client_id
    client_secret = each.value.client_secret
  })
}

data "aws_iam_policy_document" "m2m_kms_policy" {
  for_each = { for pool in var.user_pools : pool.name => pool }
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", data.aws_caller_identity.current.account_id)]
    }
  }

  dynamic "statement" {
    for_each = contains(keys(local.m2m_accessing_account_principals), each.key) ? [1] : []
    content {
      sid       = "AllowAccessForTheAccessingSolutionAccounts"
      effect    = "Allow"
      actions   = ["kms:Decrypt"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = local.m2m_accessing_account_principals[each.key]
      }
    }
  }
}

resource "aws_kms_key" "secret_kms_key" {
  for_each = { for pool in var.user_pools : pool.name => pool }

  description         = "KMS key per user pool to encrypt client secrets"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.m2m_kms_policy[each.key].json
}

# ---------------------------------------------------------------------------------------------------------------------
# ¦ M2M CLIENT SECRET POLICIES
# ---------------------------------------------------------------------------------------------------------------------
data "aws_iam_policy_document" "m2m_secret_policies" {
  for_each = {
    for client_key, client in aws_cognito_user_pool_client.m2m_clients :
    client_key => {
      accessing_solution_account_id = local.m2m_clients[client_key].accessing_solution_account_id
    }
  }

  statement {
    sid    = "EnableAnotherAWSAccountToReadTheSecret"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", each.value.accessing_solution_account_id)]
    }

    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["*"]
  }
}

resource "aws_secretsmanager_secret_policy" "m2m_secret_policies" {
  for_each = {
    for client_key, client in aws_cognito_user_pool_client.m2m_clients :
    client_key => aws_secretsmanager_secret.m2m_secrets[client_key].arn
  }

  secret_arn = each.value
  policy     = data.aws_iam_policy_document.m2m_secret_policies[each.key].json
}
