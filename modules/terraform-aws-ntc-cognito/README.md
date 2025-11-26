# AWS Cognito User Pool Module

This Terraform module provisions and manages AWS Cognito User Pools with comprehensive support for authentication and authorization, including Identity Providers (IdPs), custom domains, OAuth 2.0 app clients, machine-to-machine (M2M) authentication, and manual user/group management.

## 🎯 Purpose

The module creates a complete, production-ready authentication infrastructure that:
- Supports multiple authentication strategies (IdP federation or manual user management)
- Provides secure OAuth 2.0/OIDC integration for web and mobile applications
- Enables machine-to-machine authentication with client credentials flow
- Implements fine-grained access control through groups
- Manages M2M secrets securely in AWS Secrets Manager with KMS encryption
- Supports custom and Cognito-hosted domains with optional ACM certificates

## 📋 Features

### **Authentication Strategies**
- **IdP Federation**: SAML, OIDC, and social providers (Google, Facebook, Amazon, Apple)
- **Manual User Management**: Built-in Cognito authentication with direct user provisioning
- **Mutual Exclusivity**: User pools can use IdPs OR manual users, but not both (enforced by validation)

### **OAuth 2.0 & App Clients**
- OAuth 2.0 app clients with configurable callback URLs
- Support for multiple IdPs per client (validated against pool's IdP list)
- Client credentials flow for M2M authentication
- Configurable token validity (supports seconds, minutes, hours, days)

### **Access Control**
- User-to-group membership management (validated against defined groups)
- Custom schema attributes with data type constraints
- Attribute mapping from IdPs to Cognito attributes (including custom attributes)

### **Security**
- Customer-managed KMS encryption per user pool for M2M secrets
- AWS Secrets Manager integration with cross-account access policies
- Admin-only account recovery (no self-service password reset)
- Advanced security mode support (OFF, AUDIT, ENFORCED)
- WAFv2 Web ACL association support
- Admin-only user creation enforced
- Token revocation enabled by default
- Prevention of user existence errors

### **Scalability**
- Multiple user pools in a single deployment
- Dynamic resource creation based on configuration
- Centralized secrets management per user pool
- Cross-account KMS and Secrets Manager access for M2M clients

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Cognito User Pool Module                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐    │
│  │   User Pools     │  │  Custom Domains  │  │  Identity Providers     │    │
│  │                  │  │                  │  │                         │    │
│  │ • Admin create   │  │ • Custom domain  │  │ • SAML (EntraID, etc)   │    │
│  │   only mode      │  │ • Cognito domain │  │ • OIDC providers        │    │
│  │ • Custom schema  │  │ • ACM cert       │  │ • Social (Google, FB)   │    │
│  │ • Advanced sec   │  │   (optional)     │  │ • Attribute mapping     │    │
│  │ • WAF assoc      │  │                  │  │ • IdP identifiers       │    │
│  └──────────────────┘  └──────────────────┘  └─────────────────────────┘    │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐    │
│  │   App Clients    │  │   M2M Clients    │  │  Groups & Users         │    │
│  │                  │  │                  │  │                         │    │
│  │ • OAuth 2.0      │  │ • Client creds   │  │ • Group hierarchy       │    │
│  │ • Multi-IdP      │  │ • Resource       │  │ • User provisioning     │    │
│  │ • Callback URLs  │  │   servers        │  │ • Membership mgmt       │    │
│  │ • Token config   │  │ • Custom scopes  │  │ • Custom attributes     │    │
│  └──────────────────┘  └──────────────────┘  └─────────────────────────┘    │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                                 │
│  │  Secrets Mgmt    │  │  KMS Encryption  │                                 │
│  │                  │  │                  │                                 │
│  │ • M2M secrets    │  │ • Per-pool key   │                                 │
│  │ • Cross-account  │  │ • Cross-account  │                                 │
│  │   access         │  │   access         │                                 │
│  └──────────────────┘  └──────────────────┘                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 🔐 Authentication Flows

### IdP-Based Authentication (SSO)
```
┌──────────┐         ┌──────────┐         ┌──────────┐         ┌──────────┐
│   User   │────────▶│ Cognito  │────────▶│   IdP    │────────▶│   App    │
│          │  Login  │ Hosted   │  SAML/  │ (EntraID)│  Token  │  Client  │
│          │         │   UI     │  OIDC   │          │         │          │
└──────────┘         └──────────┘         └──────────┘         └──────────┘
```

### Manual User Authentication
```
┌──────────┐         ┌──────────┐         ┌──────────┐
│   User   │────────▶│ Cognito  │────────▶│   App    │
│          │  Login  │  Native  │  Token  │  Client  │
│          │         │   Auth   │         │          │
└──────────┘         └──────────┘         └──────────┘
```

### Machine-to-Machine (M2M)
```
┌──────────┐         ┌──────────┐         ┌──────────┐
│ Service  │────────▶│ Cognito  │────────▶│   API    │
│    A     │  Client │  Token   │  Access │ Service  │
│          │  Creds  │ Endpoint │  Token  │    B     │
└──────────┘         └──────────┘         └──────────┘
```

## ⚠️ Important Constraints & Validations

The module enforces several important validations to ensure proper configuration:

### Mutual Exclusivity: IdPs vs. Manual Users
- **User pools with IdPs configured (idps != []) CANNOT have manual users**
- **User pools without IdPs (idps = []) CAN have manual users**
- This is enforced by validation: `length(pool.users) == 0 || length(pool.idps) == 0`

### App Client IdP References
- All IdPs listed in `app_clients[].supported_idps` must exist in the pool's `idps[].provider_name` list
- Use `"COGNITO"` for built-in authentication

### User Group Memberships
- All groups referenced in `users[].groups` must be defined in the pool's `groups[].name` list
- This ensures referential integrity for user-to-group assignments

### Custom Attribute Mapping
- Custom attributes referenced in IdP `attribute_mapping` (format: `"custom:AttributeName"`) must be defined in `custom_attributes[].name`
- Example: To map `"custom:AadGroups"`, you must define an attribute with `name = "AadGroups"` in `custom_attributes`

### Token Validity Format
- `auth_session_validity`: Must use format `<number>m` (minutes only), e.g., `"3m"`
- `refresh_token_validity`, `access_token_validity`, `id_token_validity`: Must use format `<number><unit>` where unit is:
  - `s` = seconds
  - `m` = minutes
  - `h` = hours
  - `d` = days
  - Examples: `"30s"`, `"60m"`, `"1h"`, `"30d"`

### Naming Constraints
- User pool names: 1-128 characters
- IdP provider names: 1-32 characters (unique within pool)
- All names must be unique within their respective scope

### Advanced Security Mode
- `OFF`: Cognito Essentials tier (default, no cost)
- `AUDIT`: Cognito Plus tier (additional cost, audit mode)
- `ENFORCED`: Cognito Plus tier (additional cost, enforcement mode)

## 🔧 Usage

### Basic Example: IdP-Based Authentication

```hcl
module "cognito" {
  source = "./modules/terraform-aws-cognito"
  
  user_pools = [
    {
      name = "production-app"
      
      domain = {
        name            = "auth.myapp.com"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
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
      
      groups = [
        {
          name        = "administrators"
          description = "System administrators with full access"
          precedence  = 1
        },
        {
          name        = "users"
          description = "Standard users"
          precedence  = 10
        }
      ]
      
      app_clients = [
        {
          name           = "web-app"
          callback_urls  = [
            "https://myapp.com/callback",
            "https://myapp.com/oauth2/idpresponse"
          ]
          supported_idps        = ["EntraID"]
          auth_session_validity = "3m"     # 3 minutes (default)
          refresh_token_validity = "30d"   # 30 days (default)
          access_token_validity  = "60m"   # 60 minutes (default)
          id_token_validity      = "60m"   # 60 minutes (default)
        }
      ]
    }
  ]
}
```

### Manual User Management Example

```hcl
module "cognito_internal" {
  source = "./modules/terraform-aws-cognito"
  
  user_pools = [
    {
      name = "internal-tools"
      
      domain = {
        name = "internal-auth"
      }
      
      # Empty IdPs list enables manual user management
      idps = []
      
      groups = [
        {
          name        = "admins"
          description = "Admin users"
          precedence  = 1
        },
        {
          name        = "developers"
          description = "Developer access"
          precedence  = 5
        }
      ]
      
      users = [
        {
          username = "admin@company.com"
          email    = "admin@company.com"
          groups   = ["admins"]
          attributes = {
            given_name  = "Admin"
            family_name = "User"
          }
        },
        {
          username = "dev@company.com"
          email    = "dev@company.com"
          groups   = ["developers"]
        }
      ]
      
      app_clients = [
        {
          name           = "internal-portal"
          callback_urls  = ["https://tools.internal.company.com/callback"]
          supported_idps = ["COGNITO"]
        }
      ]
    }
  ]
}
```

### M2M Authentication Example

```hcl
module "cognito_services" {
  source = "./modules/terraform-aws-cognito"
  
  user_pools = [
    {
      name = "service-auth"
      
      domain = {
        name = "services-auth"
      }
      
      idps = []
      
      m2m_clients = [
        {
          name                          = "api-gateway"
          accessing_solution_account_id = "123456789012"
          custom_scope_name             = "api.read"
          custom_scope_description      = "Read access to API resources"
          auth_session_validity         = "3m"
          refresh_token_validity        = "30d"
          access_token_validity         = "60m"
          id_token_validity             = "60m"
        },
        {
          name                          = "data-pipeline"
          accessing_solution_account_id = "234567890123"
          custom_scope_name             = "data.write"
          custom_scope_description      = "Write access to data lake"
          auth_session_validity         = "3m"
          refresh_token_validity        = "30d"
          access_token_validity         = "1h"
          id_token_validity             = "1h"
        }
      ]
    }
  ]
}
```

### Multi-Pool Complex Example

```hcl
module "cognito_multi" {
  source = "./modules/terraform-aws-cognito"
  
  user_pools = [
    # Customer-facing pool with social providers
    {
      name = "customer-auth"
      domain = {
        name            = "customer-login.myapp.com"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
      }
      idps = [
        {
          provider_name = "Google"
          provider_type = "Google"
          provider_details = {
            client_id        = "google-client-id"
            client_secret    = "google-client-secret"
            authorize_scopes = "email profile openid"
          }
          attribute_mapping = {
            email    = "email"
            username = "sub"
          }
        },
        {
          provider_name = "Facebook"
          provider_type = "Facebook"
          provider_details = {
            client_id        = "facebook-app-id"
            client_secret    = "facebook-app-secret"
            authorize_scopes = "email public_profile"
          }
          attribute_mapping = {
            email    = "email"
            username = "id"
          }
        }
      ]
      groups = [
        {
          name        = "premium"
          description = "Premium users"
          precedence  = 5
        },
        {
          name        = "standard"
          description = "Standard users"
          precedence  = 10
        }
      ]
      app_clients = [
        {
          name           = "web-client"
          callback_urls  = ["https://myapp.com/auth/callback"]
          supported_idps = ["Google", "Facebook"]
        },
        {
          name           = "mobile-client"
          callback_urls  = ["myapp://callback"]
          supported_idps = ["Google", "Facebook"]
        }
      ]
    },
    
    # Internal employee pool with corporate SSO and custom attributes
    {
      name = "employee-auth"
      domain = {
        name            = "employee-sso.company.internal"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
      }
      
      custom_attributes = [
        {
          name                = "AadGroups"
          attribute_data_type = "String"
          mutable             = true
          string_attribute_constraints = {
            min_length = 0
            max_length = 2048
          }
        },
        {
          name                = "EmployeeId"
          attribute_data_type = "Number"
          mutable             = false
          number_attribute_constraints = {
            min_value = 1
            max_value = 999999
          }
        }
      ]
      
      idps = [
        {
          provider_name = "CorporateAD"
          provider_type = "SAML"
          provider_details = {
            MetadataURL = "https://login.microsoftonline.com/tenant-id/federationmetadata/2007-06/federationmetadata.xml"
          }
          attribute_mapping = {
            email              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            username           = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            "custom:AadGroups" = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"
          }
          idp_identifiers = []
        }
      ]
      
      groups = [
        {
          name        = "engineering"
          description = "Engineering team"
          precedence  = 5
        },
        {
          name        = "product"
          description = "Product team"
          precedence  = 10
        }
      ]
      
      plus_features = {
        advanced_security_mode = "AUDIT"
      }
      
      waf_configuration = {
        web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/..."
      }
      
      app_clients = [
        {
          name           = "internal-tools"
          callback_urls  = ["https://admin.company.internal/callback"]
          supported_idps = ["CorporateAD"]
        }
      ]
      
      m2m_clients = [
        {
          name                          = "monitoring"
          accessing_solution_account_id = "345678901234"
          custom_scope_name             = "metrics.read"
          custom_scope_description      = "Read monitoring metrics"
        }
      ]
    }
  ]
}
```

## � Accessing M2M Client Secrets

The module stores M2M client credentials in AWS Secrets Manager. Here's how to access them in your Terraform configuration:

### Using the M2M Secrets Output

```hcl
module "cognito" {
  source = "./modules/terraform-aws-cognito"
  # ... your configuration
}

# Access M2M client secrets using data sources
data "aws_secretsmanager_secret_version" "m2m_client_secret" {
  for_each  = module.cognito.m2m_secrets
  secret_id = each.value.secret_arn
}

# Parse the JSON secret value
locals {
  m2m_client_credentials = {
    for key, secret in data.aws_secretsmanager_secret_version.m2m_client_secret :
    key => jsondecode(secret.secret_string)
  }
}
```

### Output Structure

The `m2m_secrets` output provides:
- `secret_arn`: ARN for the Secrets Manager secret
- `secret_name`: Name of the secret (format: `{user_pool_name}_{client_name}`)
- `kms_key_id`: KMS key used for encryption

The secret contains JSON with:
```json
{
  "client_id": "cognito-client-id", 
  "client_secret": "cognito-client-secret"
}
```

### User Pool Object Structure

```hcl
{
  name = string  # User pool identifier (1-128 chars, used in resource names)
  
  domain = object({
    name            = string           # Domain prefix or custom domain FQDN
    certificate_arn = optional(string) # Required for custom domains (must be in us-east-1)
  })
  
  idps = list(object({  # Empty list = no IdPs (enables manual user management)
    provider_name     = string                 # Unique name within pool (1-32 chars)
    provider_type     = string                 # SAML, OIDC, Google, Facebook, LoginWithAmazon, SignInWithApple
    provider_details  = map(string)            # Provider-specific configuration
    attribute_mapping = optional(map(string))  # Map IdP attributes to Cognito (including custom:*)
    idp_identifiers   = optional(list(string)) # IdP identifiers for discovery
  }))
  
  groups = optional(list(object({  # Can be used with or without IdPs
    name        = string              # Group name (must be unique within pool)
    description = optional(string)    # Group description (defaults to "Managed by Terraform")
    precedence  = optional(number)    # Lower = higher priority (optional)
  })), [])
  
  users = optional(list(object({  # ONLY allowed if idps = [] (mutually exclusive)
    username   = string                    # Username (must be unique within pool)
    email      = string                    # User email address
    groups     = optional(list(string), []) # List of group names (must exist in groups)
    attributes = optional(map(string), {})  # Additional custom attributes
  })), [])
  
  custom_attributes = optional(list(object({
    name                = string                      # Attribute name (without "custom:" prefix)
    attribute_data_type = string                      # String, Number, DateTime, Boolean
    developer_only_attribute = optional(bool, false)  # Developer-only flag
    mutable                  = optional(bool, true)   # Whether attribute can be modified
    required                 = optional(bool, false)  # Whether attribute is required
    string_attribute_constraints = optional(object({  # For String type only
      min_length = optional(number)
      max_length = optional(number)
    }))
    number_attribute_constraints = optional(object({  # For Number type only
      min_value = optional(number)
      max_value = optional(number)
    }))
  })), [])
  
  plus_features = optional(object({
    advanced_security_mode = optional(string, "OFF")  # OFF (default), AUDIT, or ENFORCED
  }), { advanced_security_mode = "OFF" })
  
  waf_configuration = optional(object({
    web_acl_arn = string  # ARN of the WAFv2 Web ACL to associate
  }))
  
  app_clients = optional(list(object({
    name                    = string              # Client name (must be unique within pool)
    callback_urls           = list(string)        # OAuth callback URLs
    supported_idps          = list(string)        # List of IdP provider_names (must exist in idps)
    auth_session_validity   = optional(string, "3m")   # Format: <number>m (minutes only)
    refresh_token_validity  = optional(string, "30d")  # Format: <number><s|m|h|d>
    access_token_validity   = optional(string, "60m")  # Format: <number><s|m|h|d>
    id_token_validity       = optional(string, "60m")  # Format: <number><s|m|h|d>
  })), [])
  
  m2m_clients = optional(list(object({
    name                          = string           # M2M client name (must be unique within pool)
    accessing_solution_account_id = string           # AWS Account ID (12-digit number)
    custom_scope_name             = string           # OAuth scope name
    custom_scope_description      = string           # Scope description
    auth_session_validity         = optional(string, "3m")   # Format: <number>m (minutes only)
    refresh_token_validity        = optional(string, "30d")  # Format: <number><s|m|h|d>
    access_token_validity         = optional(string, "60m")  # Format: <number><s|m|h|d>
    id_token_validity             = optional(string, "60m")  # Format: <number><s|m|h|d>
  })), [])
}
```

### Provider Details by Type

#### SAML Provider
```hcl
provider_details = {
  MetadataURL = "https://idp.example.com/metadata.xml"
  # OR
  MetadataFile = file("metadata.xml")
}

attribute_mapping = {
  email    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
  username = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
  "custom:AadGroups" = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"
}
```

#### OIDC Provider
```hcl
provider_details = {
  client_id                 = "oidc-client-id"
  client_secret             = "oidc-client-secret"
  attributes_request_method = "GET"
  oidc_issuer              = "https://accounts.google.com"
  authorize_scopes         = "openid email profile"
}

attribute_mapping = {
  email    = "email"
  username = "sub"
  name     = "name"
}
```

#### Social Providers (Google, Facebook)
```hcl
# Google
provider_details = {
  client_id        = "google-client-id.apps.googleusercontent.com"
  client_secret    = "google-client-secret"
  authorize_scopes = "email profile openid"
}

# Facebook
provider_details = {
  client_id        = "facebook-app-id"
  client_secret    = "facebook-app-secret"
  authorize_scopes = "email public_profile"
  api_version      = "v12.0"
}
```

### Output Details

#### `app_client_map_by_pool`
```hcl
{
  "pool-name" = {
    "pool-name_client-name" = {
      name               = "client-name"
      user_pool_name     = "pool-name"
      user_pool_id       = "eu-central-1_ABC123"
      user_pool_arn      = "arn:aws:cognito-idp:..."
      client_id          = "1234567890abcdef"
      authorize_endpoint = "https://domain.auth.region.amazoncognito.com/oauth2/authorize"
      token_endpoint     = "https://domain.auth.region.amazoncognito.com/oauth2/token"
      userinfo_endpoint  = "https://domain.auth.region.amazoncognito.com/oauth2/userInfo"
    }
  }
}
```

#### `m2m_client_map_by_pool`
```hcl
{
  "pool-name" = {
    "pool-name_client-name" = {
      name                          = "client-name"
      user_pool_name                = "pool-name"
      user_pool_id                  = "eu-central-1_ABC123"
      user_pool_arn                 = "arn:aws:cognito-idp:..."
      authorize_endpoint            = "https://domain.auth.region.amazoncognito.com/oauth2/authorize"
      token_endpoint                = "https://domain.auth.region.amazoncognito.com/oauth2/token"
      secret_arn                    = "arn:aws:secretsmanager:..."
      custom_scope_identifier       = "pool-name/client-name/scope.name"
      accessing_solution_account_id = "123456789012"
    }
  }
}
```

#### `m2m_secrets`
```hcl
{
  "pool-name_client-name" = {
    secret_arn  = "arn:aws:secretsmanager:region:account:secret:pool-name_client-name"
    secret_name = "pool-name_client-name"
    kms_key_id  = "arn:aws:kms:region:account:key/key-id"
  }
}
```

<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.8 |
| archive | 2.7.1 |
| aws | 5.98.0 |

### Providers

| Name | Version |
|------|---------|
| aws | 5.98.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_cognito_identity_provider.idps](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_identity_provider) | resource |
| [aws_cognito_resource_server.resource_servers](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_resource_server) | resource |
| [aws_cognito_user.users](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user) | resource |
| [aws_cognito_user_group.groups](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_group) | resource |
| [aws_cognito_user_in_group.user_group_memberships](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_in_group) | resource |
| [aws_cognito_user_pool.user_pools](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_pool) | resource |
| [aws_cognito_user_pool_client.app_clients](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_client.m2m_clients](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_pool_client) | resource |
| [aws_cognito_user_pool_domain.domains](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/cognito_user_pool_domain) | resource |
| [aws_kms_key.secret_kms_key](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/kms_key) | resource |
| [aws_secretsmanager_secret.m2m_secrets](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_policy.m2m_secret_policies](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/secretsmanager_secret_policy) | resource |
| [aws_secretsmanager_secret_version.m2m_secret_versions](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/secretsmanager_secret_version) | resource |
| [aws_wafv2_web_acl_association.user_pool_waf](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/resources/wafv2_web_acl_association) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.m2m_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.m2m_secret_policies](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| user\_pools | List of Cognito user pools with their IdPs, domain config, and clients | <pre>list(object({<br/>    name = string<br/>    domain = object({<br/>      name            = string<br/>      certificate_arn = optional(string)<br/>    })<br/><br/>    idps = list(object({<br/>      provider_name     = string<br/>      provider_type     = string<br/>      provider_details  = map(string)<br/>      attribute_mapping = optional(map(string))<br/>      idp_identifiers   = optional(list(string))<br/>    }))<br/><br/>    groups = optional(list(object({<br/>      name        = string<br/>      description = optional(string)<br/>      precedence  = optional(number)<br/>    })), [])<br/><br/>    users = optional(list(object({<br/>      username   = string<br/>      email      = string<br/>      groups     = optional(list(string), [])<br/>      attributes = optional(map(string), {})<br/>    })), [])<br/><br/>    custom_attributes = optional(list(object({<br/>      name                     = string<br/>      attribute_data_type      = string # String, Number, DateTime, Boolean<br/>      developer_only_attribute = optional(bool, false)<br/>      mutable                  = optional(bool, true)<br/>      required                 = optional(bool, false)<br/>      string_attribute_constraints = optional(object({<br/>        min_length = optional(number)<br/>        max_length = optional(number)<br/>      }))<br/>      number_attribute_constraints = optional(object({<br/>        min_value = optional(number)<br/>        max_value = optional(number)<br/>      }))<br/>    })), [])<br/><br/>    plus_features = optional(object({<br/>      advanced_security_mode = optional(string, "OFF") # OFF (Essentials tier), AUDIT, or ENFORCED (Plus tier)<br/>    }), {<br/>      advanced_security_mode = "OFF"<br/>    })<br/><br/>    waf_configuration = optional(object({<br/>      web_acl_arn = string # ARN of the WAFv2 Web ACL to associate with the user pool<br/>    }))<br/><br/>    app_clients = optional(list(object({<br/>      name                    = string<br/>      callback_urls           = list(string)<br/>      supported_idps          = list(string)<br/>      auth_session_validity   = optional(string, "3m")  # format: <number>m (minutes only)<br/>      refresh_token_validity  = optional(string, "30d") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>      access_token_validity   = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>      id_token_validity       = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>    })), [])<br/><br/>    m2m_clients = optional(list(object({<br/>      name                          = string<br/>      accessing_solution_account_id = string<br/>      custom_scope_name             = string<br/>      custom_scope_description      = string<br/>      auth_session_validity         = optional(string, "3m")  # format: <number>m (minutes only)<br/>      refresh_token_validity        = optional(string, "30d") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>      access_token_validity         = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>      id_token_validity             = optional(string, "60m") # format: <number><unit> where unit is s(seconds), m(minutes), h(hours), or d(days)<br/>    })), [])<br/>  }))</pre> | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| app\_client\_map\_by\_pool | App client configuration details organized by user pool |
| cognito\_groups | Map of group keys to group details |
| cognito\_users | Map of user keys to user details (excluding sensitive data) |
| identity\_providers | Map of identity provider keys to provider names |
| m2m\_client\_map\_by\_pool | M2M client configuration details organized by user pool |
| m2m\_secrets | Map of M2M client secrets in AWS Secrets Manager |
| user\_pool\_arns | Map of user pool names to user pool ARNs |
| user\_pool\_domains | Map of user pool names to user pool domain names |
| user\_pool\_ids | Map of user pool names to user pool IDs |
<!-- END_TF_DOCS -->