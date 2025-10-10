# OpenTofu Tests for terraform-aws-cognito Module

This directory contains automated tests for the `terraform-aws-cognito` module using OpenTofu's native testing framework.

## 📋 Test Overview

The test suite validates the following functionality:

### Test Cases

1. **Basic User Pool** (`basic_user_pool`)
   - Validates user pool creation with minimal configuration
   - Checks user pool domain setup

2. **SAML Identity Provider** (`user_pool_with_saml_idp`)
   - Tests SAML IdP integration (e.g., EntraID)
   - Validates attribute mapping

3. **OIDC Identity Provider** (`user_pool_with_oidc_idp`)
   - Tests OIDC IdP integration (e.g., Google)
   - Validates OAuth 2.0 configuration

4. **App Client Configuration** (`app_client_configuration`)
   - Tests OAuth 2.0 app client creation
   - Validates callback URLs and supported IdPs
   - Checks OAuth endpoints (authorize, token, userinfo)

5. **M2M Client Configuration** (`m2m_client_configuration`)
   - Tests machine-to-machine client creation
   - Validates client credentials flow setup
   - Checks secrets management integration

6. **Groups and Users** (`groups_and_users`)
   - Tests manual user provisioning
   - Validates group creation and precedence
   - Checks user-to-group membership

7. **Multiple User Pools** (`multiple_user_pools`)
   - Validates multiple pool management
   - Tests pool isolation

8. **Validation: Users without Groups** (`validation_users_without_groups`)
   - Ensures users must belong to defined groups
   - Tests input validation

9. **Validation: Invalid IdP Reference** (`validation_app_client_invalid_idp`)
   - Ensures app clients reference valid IdPs
   - Tests referential integrity

10. **Validation: Users with IdPs** (`validation_users_with_idps`)
    - Ensures users and IdPs are mutually exclusive
    - Tests configuration constraints

11. **Output Structure** (`output_structure`)
    - Validates all output formats
    - Ensures consistent data structure

## 🚀 Running the Tests

### Prerequisites

- OpenTofu >= 1.8.0 or Terraform >= 1.9.0
- AWS credentials configured with permissions for:
  - Cognito (User Pools, Identity Providers, Domains)
  - Secrets Manager
  - KMS
  - Lambda (for token customization)

### Running All Tests

```bash
# From the module root directory
cd /path/to/terraform-aws-cognito
tofu test

# Or with Terraform
terraform test
```

### Running Specific Tests

```bash
# Run a specific test file
tofu test -filter=tests/cognito_test.tftest.hcl

# Run tests with verbose output
tofu test -verbose

# Run only tests that match a pattern
tofu test -filter='*user_pool*'
```

### Test Execution Modes

```bash
# Plan-only tests (faster, no actual resources)
tofu test

# Apply tests (creates real resources - be aware of costs!)
# Note: Most tests use command = plan to avoid costs
tofu test -verbose
```

## 📊 Test Scenarios Covered

### Authentication Strategies

| Scenario | Test Coverage |
|----------|---------------|
| IdP Federation (SAML) | ✅ |
| IdP Federation (OIDC) | ✅ |
| Manual User Management | ✅ |
| Mixed (IdP + Groups) | ✅ |

### Client Types

| Client Type | Test Coverage |
|-------------|---------------|
| OAuth 2.0 App Clients | ✅ |
| M2M Clients (Client Credentials) | ✅ |
| Multiple Clients per Pool | ✅ |

### Access Control

| Feature | Test Coverage |
|---------|---------------|
| Group Creation | ✅ |
| Group Precedence | ✅ |
| User Provisioning | ✅ |
| User-Group Membership | ✅ |

### Validation Rules

| Validation | Test Coverage |
|------------|---------------|
| Unique Pool Names | ✅ |
| Unique IdP Names | ✅ |
| Valid IdP References | ✅ |
| Users XOR IdPs | ✅ |
| Group Membership Validation | ✅ |

## 🔍 Understanding Test Results

### Successful Test Output

```
tests/cognito_test.tftest.hcl... in progress
  run "basic_user_pool"... pass
  run "user_pool_with_saml_idp"... pass
  run "user_pool_with_oidc_idp"... pass
  run "app_client_configuration"... pass
  run "m2m_client_configuration"... pass
  run "groups_and_users"... pass
  run "multiple_user_pools"... pass
  run "validation_users_without_groups"... pass
  run "validation_app_client_invalid_idp"... pass
  run "validation_users_with_idps"... pass
  run "output_structure"... pass
tests/cognito_test.tftest.hcl... tearing down
tests/cognito_test.tftest.hcl... pass

Success! 11 passed, 0 failed.
```

### Failed Test Output

When a test fails, you'll see detailed error messages:

```
tests/cognito_test.tftest.hcl... in progress
  run "app_client_configuration"... fail
    Error: All app clients should have OAuth endpoints configured
    
    with output.app_client_map_by_pool,
    on outputs.tf line 1, in output "app_client_map_by_pool":
     1:   value = local.app_client_map_by_pool
```

## 🛠️ Troubleshooting

### Common Issues

**Test fails with "Insufficient permissions"**
- Verify AWS credentials have Cognito, Secrets Manager, and KMS permissions
- Check IAM policies allow resource creation in the target account/region

**Test fails on M2M client tests**
- Ensure KMS key creation permissions are available
- Verify Secrets Manager is accessible in the region

**Validation tests not failing as expected**
- Check that you're using the correct variable validation syntax
- Ensure OpenTofu/Terraform version supports test validation

**Tests taking too long**
- Use `command = plan` instead of `command = apply` for faster execution
- Run specific test subsets using `-filter` flag

### Debug Mode

Enable detailed logging:

```bash
export TF_LOG=DEBUG
tofu test -verbose
```

Or for specific components:

```bash
export TF_LOG_PROVIDER=DEBUG
export TF_LOG_CORE=DEBUG
tofu test
```

## 📝 Test Development Guidelines

When adding new features to the module:

1. **Add corresponding test cases** for the new functionality
2. **Include validation tests** to ensure proper error handling
3. **Test both positive and negative scenarios**
4. **Update this README** with new test information
5. **Ensure tests use `command = plan`** by default to avoid costs

### Test Structure Template

```hcl
run "descriptive_test_name" {
  command = plan

  variables {
    user_pools = [
      {
        # Your test configuration
      }
    ]
  }

  # Assertions
  assert {
    condition     = <expression>
    error_message = "Descriptive error message"
  }
}
```

## 🔒 Security Considerations

- Tests use `command = plan` to avoid creating real AWS resources
- Sensitive data should never be hardcoded in tests
- Use mock/example values for secrets and credentials
- Consider using separate AWS accounts for integration testing

## 📚 Additional Resources

- [OpenTofu Testing Documentation](https://opentofu.org/docs/language/tests/)
- [Terraform Testing Documentation](https://developer.hashicorp.com/terraform/language/tests)
- [Module Documentation](../README.md)
- [AWS Cognito Documentation](https://docs.aws.amazon.com/cognito/)

## 🤝 Contributing

When contributing to this module:

1. Run the full test suite: `tofu test`
2. Add tests for new features
3. Update tests for modified features
4. Ensure all tests pass before submitting PR
5. Update documentation if test behavior changes

```bash
# Pre-commit checklist
tofu fmt tests/
tofu test
tofu validate
```

---

**Note**: These tests primarily use `command = plan` which validates configuration without creating actual resources. For integration testing with real resources, create separate test files with `command = apply` and appropriate cleanup procedures.
