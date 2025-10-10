# ---------------------------------------------------------------------------------------------------------------------
# OpenTofu Test for terraform-aws-cognito module
# ---------------------------------------------------------------------------------------------------------------------
# This test file validates the cognito module's ability to:
# 1. Create Cognito user pools with custom configuration
# 2. Configure identity providers (SAML, OIDC)
# 3. Create app clients with OAuth 2.0 support
# 4. Create M2M clients with client credentials flow
# 5. Manage groups and users
# 6. Configure custom domains
# ---------------------------------------------------------------------------------------------------------------------

# Test 1: Basic User Pool Creation
run "basic_user_pool" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-user-pool"
        domain = {
          name = "test-pool-domain"
        }
        idps        = []
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  # Validate user pool is created
  assert {
    condition     = length(keys(output.user_pool_ids)) == 1
    error_message = "Should create exactly one user pool"
  }

  assert {
    condition     = contains(keys(output.user_pool_ids), "test-user-pool")
    error_message = "User pool should be named 'test-user-pool'"
  }

  # Validate user pool domain is created
  assert {
    condition     = length(keys(output.user_pool_domains)) == 1
    error_message = "Should create exactly one user pool domain"
  }

  assert {
    condition     = output.user_pool_domains["test-user-pool"] == "test-pool-domain"
    error_message = "Domain should be 'test-pool-domain'"
  }
}

# Test 2: User Pool with SAML Identity Provider
run "user_pool_with_saml_idp" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-pool-with-saml"
        domain = {
          name = "test-saml-domain"
        }
        idps = [
          {
            provider_name = "EntraID"
            provider_type = "SAML"
            provider_details = {
              MetadataURL = "https://login.microsoftonline.com/tenant-id/federationmetadata/2007-06/federationmetadata.xml"
            }
            attribute_mapping = {
              email    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
              username = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            }
          }
        ]
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  # Validate IdP is created
  assert {
    condition     = length(keys(output.identity_providers)) == 1
    error_message = "Should create exactly one identity provider"
  }

  assert {
    condition     = contains(values(output.identity_providers), "EntraID")
    error_message = "Identity provider should be named 'EntraID'"
  }
}

# Test 3: User Pool with OIDC Identity Provider
run "user_pool_with_oidc_idp" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-pool-with-oidc"
        domain = {
          name = "test-oidc-domain"
        }
        idps = [
          {
            provider_name = "GoogleOIDC"
            provider_type = "OIDC"
            provider_details = {
              client_id                 = "google-client-id"
              client_secret             = "google-client-secret"
              authorize_scopes          = "openid email profile"
              oidc_issuer               = "https://accounts.google.com"
              attributes_request_method = "GET"
            }
            attribute_mapping = {
              email    = "email"
              username = "sub"
            }
          }
        ]
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  # Validate OIDC IdP is created
  assert {
    condition     = length(keys(output.identity_providers)) == 1
    error_message = "Should create exactly one identity provider"
  }
}

# Test 4: App Client Configuration
run "app_client_configuration" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-pool-with-client"
        domain = {
          name = "test-client-domain"
        }
        idps = [
          {
            provider_name = "TestIdP"
            provider_type = "SAML"
            provider_details = {
              MetadataURL = "https://example.com/metadata.xml"
            }
          }
        ]
        groups = []
        users  = []
        app_clients = [
          {
            name           = "web-app-client"
            callback_urls  = ["https://example.com/callback"]
            supported_idps = ["TestIdP"]
          }
        ]
        m2m_clients = []
      }
    ]
  }

  # Validate app client is created
  assert {
    condition     = length(keys(output.app_client_map_by_pool)) == 1
    error_message = "Should have app clients for one user pool"
  }

  assert {
    condition     = contains(keys(output.app_client_map_by_pool["test-pool-with-client"]), "web-app-client")
    error_message = "App client should be named 'web-app-client'"
  }

  # Validate OAuth endpoints are configured
  assert {
    condition = alltrue([
      for pool_name, clients in output.app_client_map_by_pool :
      alltrue([
        for client_name, client in clients :
        can(client.authorize_endpoint) && can(client.token_endpoint) && can(client.userinfo_endpoint)
      ])
    ])
    error_message = "All app clients should have OAuth endpoints configured"
  }
}

# Test 5: M2M Client Configuration
run "m2m_client_configuration" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-pool-with-m2m"
        domain = {
          name = "test-m2m-domain"
        }
        idps        = []
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = [
          {
            name                          = "api-client"
            accessing_solution_account_id = "123456789012"
            custom_scope_name             = "api.read"
            custom_scope_description      = "Read access to API"
          }
        ]
      }
    ]
  }

  # Validate M2M client is created
  assert {
    condition     = length(keys(output.m2m_client_map_by_pool)) == 1
    error_message = "Should have M2M clients for one user pool"
  }

  # Validate M2M secret is created
  assert {
    condition     = length(keys(output.m2m_secrets)) >= 1
    error_message = "Should create at least one M2M secret"
  }

  # Validate M2M client has token endpoint
  assert {
    condition = alltrue([
      for pool_name, clients in output.m2m_client_map_by_pool :
      alltrue([
        for client_name, client in clients :
        can(client.token_endpoint) && can(client.secret_arn)
      ])
    ])
    error_message = "All M2M clients should have token endpoint and secret ARN"
  }
}

# Test 6: Groups and Users (Manual Authentication)
run "groups_and_users" {
  command = plan

  variables {
    user_pools = [
      {
        name = "test-pool-manual-auth"
        domain = {
          name = "test-manual-domain"
        }
        idps = []
        groups = [
          {
            name        = "admins"
            description = "Administrator group"
            precedence  = 1
          },
          {
            name        = "users"
            description = "Regular users group"
            precedence  = 2
          }
        ]
        users = [
          {
            username = "admin@example.com"
            email    = "admin@example.com"
            groups   = ["admins"]
            attributes = {
              name = "Admin User"
            }
          },
          {
            username = "user@example.com"
            email    = "user@example.com"
            groups   = ["users"]
            attributes = {
              name = "Regular User"
            }
          }
        ]
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  # Validate groups are created
  assert {
    condition     = length(keys(output.cognito_groups)) == 2
    error_message = "Should create exactly two groups"
  }

  # Validate users are created
  assert {
    condition     = length(keys(output.cognito_users)) == 2
    error_message = "Should create exactly two users"
  }

  # Validate group precedence
  assert {
    condition = alltrue([
      for key, group in output.cognito_groups :
      group.name == "admins" ? group.precedence == 1 : true
    ])
    error_message = "Admins group should have precedence 1"
  }
}

# Test 7: Multiple User Pools
run "multiple_user_pools" {
  command = plan

  variables {
    user_pools = [
      {
        name = "pool-one"
        domain = {
          name = "pool-one-domain"
        }
        idps        = []
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = []
      },
      {
        name = "pool-two"
        domain = {
          name = "pool-two-domain"
        }
        idps        = []
        groups      = []
        users       = []
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  # Validate multiple pools are created
  assert {
    condition     = length(keys(output.user_pool_ids)) == 2
    error_message = "Should create exactly two user pools"
  }

  assert {
    condition     = contains(keys(output.user_pool_ids), "pool-one") && contains(keys(output.user_pool_ids), "pool-two")
    error_message = "Both user pools should be created"
  }

  # Validate both domains are created
  assert {
    condition     = length(keys(output.user_pool_domains)) == 2
    error_message = "Should create exactly two user pool domains"
  }
}

# Test 8: Validation - Users without Groups Should Fail
run "validation_users_without_groups" {
  command = plan

  variables {
    user_pools = [
      {
        name = "invalid-pool"
        domain = {
          name = "invalid-domain"
        }
        idps   = []
        groups = []
        users = [
          {
            username = "user@example.com"
            email    = "user@example.com"
            groups   = ["nonexistent-group"]
          }
        ]
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  expect_failures = [
    var.user_pools
  ]
}

# Test 9: Validation - App Client with Invalid IdP Should Fail
run "validation_app_client_invalid_idp" {
  command = plan

  variables {
    user_pools = [
      {
        name = "invalid-client-pool"
        domain = {
          name = "invalid-client-domain"
        }
        idps = [
          {
            provider_name = "ValidIdP"
            provider_type = "SAML"
            provider_details = {
              MetadataURL = "https://example.com/metadata.xml"
            }
          }
        ]
        groups = []
        users  = []
        app_clients = [
          {
            name           = "invalid-client"
            callback_urls  = ["https://example.com/callback"]
            supported_idps = ["NonExistentIdP"]
          }
        ]
        m2m_clients = []
      }
    ]
  }

  expect_failures = [
    var.user_pools
  ]
}

# Test 10: Validation - Users and IdPs Together Should Fail
run "validation_users_with_idps" {
  command = plan

  variables {
    user_pools = [
      {
        name = "conflicting-config-pool"
        domain = {
          name = "conflicting-domain"
        }
        idps = [
          {
            provider_name = "SomeIdP"
            provider_type = "SAML"
            provider_details = {
              MetadataURL = "https://example.com/metadata.xml"
            }
          }
        ]
        groups = []
        users = [
          {
            username = "user@example.com"
            email    = "user@example.com"
          }
        ]
        app_clients = []
        m2m_clients = []
      }
    ]
  }

  expect_failures = [
    var.user_pools
  ]
}

# Test 11: Output Structure Validation
run "output_structure" {
  command = plan

  variables {
    user_pools = [
      {
        name = "output-test-pool"
        domain = {
          name = "output-test-domain"
        }
        idps = [
          {
            provider_name = "TestIdP"
            provider_type = "SAML"
            provider_details = {
              MetadataURL = "https://example.com/metadata.xml"
            }
          }
        ]
        groups = [
          {
            name = "test-group"
          }
        ]
        users = []
        app_clients = [
          {
            name           = "test-client"
            callback_urls  = ["https://example.com/callback"]
            supported_idps = ["TestIdP"]
          }
        ]
        m2m_clients = []
      }
    ]
  }

  # Validate user_pool_ids output
  assert {
    condition     = can(output.user_pool_ids["output-test-pool"])
    error_message = "user_pool_ids should contain the test pool"
  }

  # Validate user_pool_arns output
  assert {
    condition     = can(output.user_pool_arns["output-test-pool"])
    error_message = "user_pool_arns should contain the test pool"
  }

  # Validate app_client_map_by_pool structure
  assert {
    condition = (
      can(output.app_client_map_by_pool["output-test-pool"]["test-client"].client_id) &&
      can(output.app_client_map_by_pool["output-test-pool"]["test-client"].authorize_endpoint) &&
      can(output.app_client_map_by_pool["output-test-pool"]["test-client"].token_endpoint)
    )
    error_message = "App client should have client_id and OAuth endpoints"
  }
}
