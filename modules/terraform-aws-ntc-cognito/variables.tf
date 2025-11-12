# ---------------------------------------------------------------------------------------------------------------------
# ¦ REQUIRED VARIABLES
# ---------------------------------------------------------------------------------------------------------------------
variable "user_pools" {
  description = "List of Cognito user pools with their IdPs, domain config, and clients"
  type = list(object({
    name = string
    domain = object({
      name            = string
      certificate_arn = optional(string)
    })

    idps = list(object({
      provider_name     = string
      provider_type     = string
      provider_details  = map(string)
      attribute_mapping = optional(map(string))
      idp_identifiers   = optional(list(string))
    }))

    groups = optional(list(object({
      name        = string
      description = optional(string)
      precedence  = optional(number)
    })), [])

    users = optional(list(object({
      username   = string
      email      = string
      groups     = optional(list(string), [])
      attributes = optional(map(string), {})
    })), [])

    app_clients = optional(list(object({
      name                    = string
      callback_urls           = list(string)
      supported_idps          = list(string)
      auth_session_validity   = optional(string, "3m")  # format: <number>m (minutes only)
      refresh_token_validity  = optional(string, "30d") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
      access_token_validity   = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
      id_token_validity       = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
    })), [])

    m2m_clients = optional(list(object({
      name                          = string
      accessing_solution_account_id = string
      custom_scope_name             = string
      custom_scope_description      = string
      auth_session_validity         = optional(string, "3m")  # format: <number>m (minutes only)
      refresh_token_validity        = optional(string, "30d") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
      access_token_validity         = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
      id_token_validity             = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)
    })), [])
  }))

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for idp in pool.idps :
        contains(["SAML", "OIDC", "Facebook", "Google", "LoginWithAmazon", "SignInWithApple"], idp.provider_type)
      ])
    ])
    error_message = "Each IdP provider_type must be one of: SAML, OIDC, Facebook, Google, LoginWithAmazon, or SignInWithApple."
  }

  validation {
    condition     = length(var.user_pools) == 0 || length(distinct([for pool in var.user_pools : pool.name])) == length(var.user_pools)
    error_message = "Each user pool name must be unique."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools :
      length(pool.name) > 0 && length(pool.name) <= 128
    ])
    error_message = "Each user pool name must be between 1 and 128 characters."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for idp in pool.idps :
        length(idp.provider_name) > 0 && length(idp.provider_name) <= 32
      ])
    ])
    error_message = "Each IdP provider_name must be between 1 and 32 characters."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : length(pool.idps) == length(distinct([
        for idp in pool.idps : idp.provider_name
      ]))
    ])
    error_message = "Each IdP provider_name must be unique within a user pool."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for idp in pool.idps :
        length(keys(idp.provider_details)) > 0
      ])
    ])
    error_message = "Each IdP must have at least one provider_details entry."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : length(pool.app_clients) == length(distinct([
        for client in pool.app_clients : client.name
      ]))
    ])
    error_message = "Each app_client name must be unique within a user pool."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for client in pool.app_clients : alltrue([
          for idp_name in client.supported_idps :
          contains([for idp in pool.idps : idp.provider_name], idp_name)
        ])
      ])
    ])
    error_message = "Each app_client's supported_idps entry must match a provider_name defined in the same user pool's idps list."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : length(pool.m2m_clients) == length(distinct([
        for client in pool.m2m_clients : client.name
      ]))
    ])
    error_message = "Each m2m_client name must be unique within a user pool."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools :
      length(pool.users) == 0 || length(pool.idps) == 0
    ])
    error_message = "Users can only be manually added to a user pool if no IDPs are configured. Remove either users or idps from the pool configuration."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : length(pool.groups) == length(distinct([
        for group in pool.groups : group.name
      ]))
    ])
    error_message = "Each group name must be unique within a user pool."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : length(pool.users) == length(distinct([
        for user in pool.users : user.username
      ]))
    ])
    error_message = "Each username must be unique within a user pool."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for user in pool.users : alltrue([
          for group_name in user.groups :
          contains([for group in pool.groups : group.name], group_name)
        ])
      ])
    ])
    error_message = "Each user's group membership must reference a group defined in the same user pool's groups list."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for client in pool.app_clients :
        can(regex("^[0-9]+m$", client.auth_session_validity))
      ])
    ])
    error_message = "auth_session_validity must be in format '<number>m' (minutes only). Example: '3m'."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for client in pool.app_clients : alltrue([
          can(regex("^[0-9]+[smhd]$", client.refresh_token_validity)),
          can(regex("^[0-9]+[smhd]$", client.access_token_validity)),
          can(regex("^[0-9]+[smhd]$", client.id_token_validity))
        ])
      ])
    ])
    error_message = "Token validity values (refresh, access, id) must be in format '<number><unit>' where unit is 's' (seconds), 'm' (minutes), 'h' (hours), or 'd' (days). Examples: '30s', '3m', '1h', '30d'."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for client in pool.m2m_clients :
        can(regex("^[0-9]+m$", client.auth_session_validity))
      ])
    ])
    error_message = "auth_session_validity must be in format '<number>m' (minutes only). Example: '3m'."
  }

  validation {
    condition = alltrue([
      for pool in var.user_pools : alltrue([
        for client in pool.m2m_clients : alltrue([
          can(regex("^[0-9]+[smhd]$", client.refresh_token_validity)),
          can(regex("^[0-9]+[smhd]$", client.access_token_validity)),
          can(regex("^[0-9]+[smhd]$", client.id_token_validity))
        ])
      ])
    ])
    error_message = "Token validity values (refresh, access, id) must be in format '<number><unit>' where unit is 's' (seconds), 'm' (minutes), 'h' (hours), or 'd' (days). Examples: '30s', '3m', '1h', '30d'."
  }
}

# TODO:
# - custom attributes via schema block
# - optional waf config
# - configurable plus features