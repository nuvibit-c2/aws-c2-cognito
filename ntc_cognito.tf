
# ---------------------------------------------------------------------------------------------------------------------
# ¦ NTC COGNITO MODULE
# ---------------------------------------------------------------------------------------------------------------------
module "ntc_cognito" {
  # TODO: Update ref to latest version after release
  source = "github.com/nuvibit-terraform-collection/terraform-aws-ntc-cognito?ref=feat/initial"

  # (optional) AWS region override - omit to use provider default region
  region = "eu-central-2"

  # List of Cognito user pools with their IdPs, domain config, and clients
  user_pools = [
    {
      # REQUIRED: Unique name for the user pool
      name = "ntc-c2-user-pool"

      # REQUIRED: Custom domain configuration for the user pool
      domain = {
        # REQUIRED: Domain prefix (results in: ntc-c2-auth.auth.<region>.amazoncognito.com)
        name = "ntc-c2-auth"

        # (optional) ACM certificate ARN for fully custom domain (e.g., auth.example.com)
        # Note: Certificate must be in us-east-1 region. Route53 configuration not handled by module.
        # certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."
      }

      # REQUIRED: Identity providers for authentication
      # Supported types: SAML, OIDC, Facebook, Google, LoginWithAmazon, SignInWithApple
      idps = [
        {
          # REQUIRED: Unique provider name within user pool
          provider_name = "EntraID"

          # REQUIRED: Identity provider type
          provider_type = "SAML"

          # REQUIRED: Provider-specific configuration (at least one key required)
          # For SAML: MetadataURL or MetadataFile
          # For OIDC: client_id, client_secret, authorize_scopes, etc.
          provider_details = {
            MetadataURL = "https://login.microsoftonline.com/<TENANT_ID>/federationmetadata/2007-06/federationmetadata.xml"
          }

          # (optional) Map IdP attributes to Cognito user attributes
          # Custom attributes must be prefixed with "custom:" and defined in custom_attributes
          attribute_mapping = {
            "custom:entraid_groups" = "http://schemas.microsoft.com/ws/2008/06/identity/claims/groups"
            name                    = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
            given_name              = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname"
            family_name             = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname"
          }

          # (optional) List of IdP identifiers for this provider
          idp_identifiers = []
        }
      ]

      # (optional) Custom attributes for user pool
      # NOTE: Custom attributes cannot be deleted or modified after creation
      custom_attributes = [
        {
          # REQUIRED: Attribute name (will be prefixed with "custom:" in Cognito)
          name = "entraid_groups"

          # REQUIRED: Data type - must be one of: String, Number, DateTime, Boolean
          attribute_data_type = "String"

          # (optional) Whether attribute can be changed after user creation (default: true)
          mutable = true

          # (optional) Whether attribute is required for user registration (default: false)
          required = false

          # (optional) Developer-only attribute (not visible to users) (default: false)
          # developer_only_attribute = false

          # (optional) Constraints for String type attributes
          string_attribute_constraints = {
            min_length = 1
            max_length = 100
          }

          # (optional) Constraints for Number type attributes
          # number_attribute_constraints = {
          #   min_value = 0
          #   max_value = 100
          # }
        }
      ]

      # (optional) User groups for authorization and access control
      groups = [
        {
          # REQUIRED: Unique group name within user pool
          name = "demo-app-administrators"

          # (optional) Group description (default: "Managed by Terraform")
          description = "Administrator users with full access on demo-app"

          # (optional) Group precedence for determining primary group (lower = higher priority)
          # precedence = 1
        },
        {
          name        = "demo-app-users"
          description = "Regular users with standard access on demo-app"
          # precedence = 2
        },
        {
          name        = "demo-app-readonly"
          description = "Read-only access users on demo-app"
          # precedence = 3
        }
      ]

      # (optional) Manually created users (only if no IdPs configured)
      # WARNING: Cannot use both IdPs and manual users in same pool
      # users = [
      #   {
      #     # REQUIRED: Username for the user
      #     username = "john.doe"
      #     
      #     # REQUIRED: User email address
      #     email = "john.doe@example.com"
      #     
      #     # (optional) List of group names to assign user to
      #     groups = ["demo-app-users"]
      #     
      #     # (optional) Additional user attributes
      #     attributes = {
      #       given_name  = "John"
      #       family_name = "Doe"
      #     }
      #   }
      # ]
      users = []

      # (optional) OAuth 2.0 app clients for web/mobile applications
      app_clients = [
        {
          # REQUIRED: Unique client name within user pool
          name = "demo-app-client"

          # REQUIRED: List of allowed callback URLs after authentication
          callback_urls = [
            "https://example.com/callback",
            "https://oauth.pstmn.io/v1/callback", # For Postman testing
            "http://localhost:3000/callback"      # For local development
          ]

          # REQUIRED: List of supported IdPs (must match provider_name from idps list)
          supported_idps = ["EntraID"]

          # (optional) Auth session validity - format: <number>m (minutes only)
          # Default: "3m"
          auth_session_validity = "5m"

          # (optional) Refresh token validity - format: <number><unit> (s/m/h/d)
          # Default: "30d"
          refresh_token_validity = "7d"

          # (optional) Access token validity - format: <number><unit> (s/m/h/d)
          # Default: "60m"
          access_token_validity = "30m"

          # (optional) ID token validity - format: <number><unit> (s/m/h/d)
          # Default: "60m"
          id_token_validity = "30m"
        }
      ]

      # (optional) Machine-to-machine (M2M) clients for machine to machine authentication via client credentials flow
      # Automatically creates: Resource Server, M2M Client, KMS Key, Secrets Manager Secret
      m2m_clients = [
        {
          # REQUIRED: Unique M2M client name within user pool
          name = "demo-app-api-service-client"

          # REQUIRED: AWS account ID that will access the secret (for cross-account access)
          accessing_solution_account_id = data.aws_caller_identity.current.account_id

          # REQUIRED: Custom OAuth scope name for this M2M client
          custom_scope_name = "api.access"

          # REQUIRED: Description of the custom scope
          custom_scope_description = "Full API access for service-to-service communication"

          # (optional) Auth session validity - format: <number>m (minutes only)
          # Default: "3m"
          auth_session_validity = "3m"

          # (optional) Refresh token validity - format: <number><unit> (s/m/h/d)
          # Default: "30d"
          refresh_token_validity = "30d"

          # (optional) Access token validity - format: <number><unit> (s/m/h/d)
          # Default: "60m"
          access_token_validity = "1h"

          # (optional) ID token validity - format: <number><unit> (s/m/h/d)
          # Default: "60m"
          id_token_validity = "1h"
        }
      ]

      # (optional) Cognito Plus features (requires Cognito Plus pricing tier)
      # plus_features = {
      #   # Advanced security mode: OFF (Essentials tier), AUDIT (Plus tier), or ENFORCED (Plus tier)
      #   # Default: "OFF"
      #   advanced_security_mode = "AUDIT"
      # }

      # (optional) AWS WAF Web ACL association for additional security
      # waf_configuration = {
      #   # REQUIRED: ARN of the WAFv2 Web ACL to associate with the user pool
      #   web_acl_arn = "arn:aws:wafv2:<region>:<account>:regional/webacl/..."
      # }
    }
  ]
}