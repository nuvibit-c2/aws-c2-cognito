# AWS Cognito User Pool Module

This Terraform module provisions and manages AWS Cognito User Pools with comprehensive support for authentication and authorization, including Identity Providers (IdPs), custom domains, OAuth 2.0 app clients, machine-to-machine (M2M) authentication, and manual user/group management.

## 🎯 Purpose

The module creates a complete, production-ready authentication infrastructure that:
- Supports multiple authentication strategies (IdP federation or manual user management)
- Provides secure OAuth 2.0/OIDC integration for web and mobile applications
- Enables machine-to-machine authentication with client credentials flow
- Implements fine-grained access control through groups
- Manages secrets securely in AWS Secrets Manager
- Supports custom domains with ACM certificates

## 📋 Features

### **Authentication Strategies**
- **IdP Federation**: SAML, OIDC, and social providers (Google, Facebook, Amazon, Apple)
- **Manual User Management**: Built-in Cognito authentication with direct user provisioning
- **Flexible Configuration**: Mix IdPs with manual groups, or go fully manual

### **OAuth 2.0 & App Clients**
- OAuth 2.0 app clients with callback URL management
- Support for multiple IdPs per client
- Automatic authorization and token endpoints
- Client credentials for M2M authentication

### **Access Control**
- Group-based authorization model
- User-to-group membership management
- Precedence-based group hierarchy
- Custom attributes support

### **Security**
- Customer-managed KMS encryption for M2M secrets
- AWS Secrets Manager integration with automatic rotation support
- HTTPS-only domain access
- Advanced security mode (audit/enforcement)
- Account recovery via admin-only

### **Scalability**
- Multiple user pools in a single deployment
- Dynamic resource creation based on configuration
- Centralized secrets management
- Cross-account access for M2M clients

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Cognito User Pool Module                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐  │
│  │   User Pools     │  │  Custom Domains  │  │  Identity Providers     │  │
│  │                  │  │                  │  │                         │  │
│  │ • Admin create   │  │ • Cognito domain │  │ • SAML (EntraID, etc)  │  │
│  │   only mode      │  │ • Custom domain  │  │ • OIDC providers       │  │
│  │ • Custom schema  │  │ • ACM cert       │  │ • Social (Google, FB)  │  │
│  │ • Advanced sec   │  │   integration    │  │ • Attribute mapping    │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────────────┘  │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────────────┐  │
│  │   App Clients    │  │   M2M Clients    │  │  Groups & Users         │  │
│  │                  │  │                  │  │                         │  │
│  │ • OAuth 2.0      │  │ • Client creds   │  │ • Group hierarchy      │  │
│  │ • Multi-IdP      │  │ • Resource       │  │ • User provisioning    │  │
│  │ • Callback URLs  │  │   servers        │  │ • Membership mgmt      │  │
│  │ • Token config   │  │ • Scopes         │  │ • Custom attributes    │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────────────┘  │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐                                │
│  │  Secrets Mgmt    │  │  KMS Encryption  │                                │
│  │                  │  │                  │                                │
│  │ • M2M secrets    │  │ • Per-client key │                                │
│  │ • Auto-rotation  │  │ • Cross-account  │                                │
│  │ • AMA access     │  │   access         │                                │
│  └──────────────────┘  └──────────────────┘                                │
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
          solution_name  = "myapp"
          callback_urls  = [
            "https://myapp.com/callback",
            "https://myapp.com/oauth2/idpresponse"
          ]
          supported_idps = ["EntraID"]
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
            department  = "IT"
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
          solution_name  = "tools"
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
        },
        {
          name                          = "data-pipeline"
          accessing_solution_account_id = "234567890123"
          custom_scope_name             = "data.write"
          custom_scope_description      = "Write access to data lake"
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
        name = "customer-login.myapp.com"
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
        },
        {
          provider_name = "Facebook"
          provider_type = "Facebook"
          provider_details = {
            client_id        = "facebook-app-id"
            client_secret    = "facebook-app-secret"
            authorize_scopes = "email public_profile"
          }
        }
      ]
      groups = [
        {
          name       = "premium"
          precedence = 5
        },
        {
          name       = "standard"
          precedence = 10
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
    
    # Internal employee pool with corporate SSO
    {
      name = "employee-auth"
      domain = {
        name = "employee-sso.company.internal"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
      }
      idps = [
        {
          provider_name = "CorporateAD"
          provider_type = "SAML"
          provider_details = {
            MetadataURL = "https://login.microsoftonline.com/..."
          }
          attribute_mapping = {
            email          = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress"
            username       = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            custom:AadGroups = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"
          }
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
  name = string  # User pool identifier (used in resource names)
  
  domain = object({
    name            = string           # Domain prefix or custom domain FQDN
    certificate_arn = optional(string) # Required for custom domains (must be in us-east-1)
  })
  
  idps = list(object({  # Empty list = no IdPs (enables manual user management)
    provider_name     = string              # Unique name within pool (1-32 chars)
    provider_type     = string              # SAML, OIDC, Google, Facebook, LoginWithAmazon, SignInWithApple
    provider_details  = map(string)         # Provider-specific configuration
    attribute_mapping = optional(map(string))  # Map IdP attributes to Cognito attributes
    idp_identifiers   = optional(list(string)) # IdP identifiers for discovery
  }))
  
  groups = optional(list(object({  # Can be used with or without IdPs
    name        = string              # Group name (must be unique within pool)
    description = optional(string)    # Group description
    precedence  = optional(number)    # Lower = higher priority (optional)
  })), [])
  
  users = optional(list(object({  # ONLY allowed if idps = []
    username   = string                    # Username (must be unique within pool)
    email      = string                    # User email address
    groups     = optional(list(string), []) # List of group names (must exist in groups)
    attributes = optional(map(string), {})  # Additional custom attributes
  })), [])
  
  app_clients = optional(list(object({
    name           = string         # Client name (must be unique within pool)
    callback_urls  = list(string)   # OAuth callback URLs
    supported_idps = list(string)   # List of IdP provider_names or "COGNITO"
  })), [])
  
  m2m_clients = optional(list(object({
    name                          = string # M2M client name (must be unique within pool)
    accessing_solution_account_id = string # AWS Account ID (12-digit number)
    custom_scope_name             = string # OAuth scope name
    custom_scope_description      = string # Scope description
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
      name                          = \"client-name\"\n      user_pool_name                = \"pool-name\"
      user_pool_id                   = "eu-central-1_ABC123"
      user_pool_arn                  = "arn:aws:cognito-idp:..."
      authorize_endpoint             = "https://..."
      token_endpoint                 = "https://..."
      secret_arn                     = \"arn:aws:secretsmanager:...\"\n      custom_scope_identifier        = \"pool-name/client-name/scope.name\"\n      accessing_solution_account_id  = \"123456789012\"
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
| terraform | >= 1.9 |
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
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.m2m_kms_policy](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.m2m_secret_policies](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.98.0/docs/data-sources/region) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| user\_pools | List of Cognito user pools with their IdPs, domain config, and clients | <pre>list(object({<br/>    name = string<br/>    domain = object({<br/>      name            = string<br/>      certificate_arn = optional(string)<br/>    })<br/><br/>    idps = list(object({<br/>      provider_name     = string<br/>      provider_type     = string<br/>      provider_details  = map(string)<br/>      attribute_mapping = optional(map(string))<br/>      idp_identifiers   = optional(list(string))<br/>    }))<br/><br/>    groups = optional(list(object({<br/>      name        = string<br/>      description = optional(string)<br/>      precedence  = optional(number)<br/>    })), [])<br/><br/>    users = optional(list(object({<br/>      username   = string<br/>      email      = string<br/>      groups     = optional(list(string), [])<br/>      attributes = optional(map(string), {})<br/>    })), [])<br/><br/>    app_clients = optional(list(object({<br/>      name           = string<br/>      callback_urls  = list(string)<br/>      supported_idps = list(string)<br/>    })), [])<br/><br/>    m2m_clients = optional(list(object({<br/>      name                          = string<br/>      accessing_solution_account_id = string<br/>      custom_scope_name             = string<br/>      custom_scope_description      = string<br/>    })), [])<br/>  }))</pre> | n/a | yes |

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