# AWS Cognito Authentication

Terraform configuration that provisions a fully-featured AWS Cognito User Pool with a hosted UI domain and optional federated identity providers.

## Resources Created

| Resource | Description |
|---|---|
| `aws_cognito_user_pool` | User pool with configurable password policy and schema |
| `aws_cognito_user_pool_client` | App client with OAuth2/PKCE settings and token validity |
| `aws_cognito_user_pool_domain` | Hosted UI domain (`{project_name}-{account_id}-domain`) |
| `aws_cognito_identity_provider.google` | Google IdP (conditional) |
| `aws_cognito_identity_provider.facebook` | Facebook IdP (conditional) |
| `aws_cognito_identity_provider.login_with_amazon` | Login with Amazon IdP (conditional) |
| `aws_cognito_identity_provider.apple` | Sign in with Apple IdP (conditional) |
| `aws_cognito_identity_provider.oidc` | Generic OIDC providers (zero or more) |
| `aws_cognito_identity_provider.saml` | SAML providers (zero or more) |

## Features

- **PKCE-ready** — client secret disabled by default for public browser-based apps
- **Dynamic IdP list** — `supported_identity_providers` on the client is derived automatically from whichever providers are actually configured; no manual list maintenance needed
- **Multiple OIDC/SAML providers** — add as many as needed via a list variable; each is created with `for_each`
- **Flexible schema** — custom user pool attributes via `user_pool_schema`
- **Managed login** — supports Cognito managed login version 1 or 2

## Prerequisites

- Terraform >= 1.x
- AWS provider `~> 6.0`
- An S3 bucket named `account-vending-terraform-state` in `eu-west-1` for remote state

## Backend

State is stored remotely in S3:

```hcl
backend "s3" {
  bucket       = "account-vending-terraform-state"
  key          = "aws-cognito/terraform.tfstate"
  region       = "eu-west-1"
  use_lockfile = true
}
```

## Usage

```hcl
# Minimal — Cognito-only login, no social IdPs
module "cognito" {
  source       = "./aws-cognito"
  project_name = "my-app"
}
```

```hcl
# With Google and a custom OIDC provider
module "cognito" {
  source       = "./aws-cognito"
  project_name = "my-app"

  idp_google = {
    enabled          = true
    client_id        = "your-google-client-id"
    client_secret    = "your-google-client-secret"
    authorize_scopes = "openid email profile"
  }

  idp_oidc_providers = [
    {
      name          = "MyOIDCProvider"
      issuer        = "https://idp.example.com"
      client_id     = "oidc-client-id"
      client_secret = "oidc-client-secret"
    }
  ]

  cognito_client_config = {
    generate_secret = false
    oauth_settings = {
      allowed_flows                = ["code"]
      allowed_scopes               = ["email", "openid", "profile"]
      allowed_flows_user_pool      = true
      supported_identity_providers = ["COGNITO"]
      explicit_auth_flows          = ["ALLOW_USER_PASSWORD_AUTH", "ALLOW_USER_SRP_AUTH", "ALLOW_REFRESH_TOKEN_AUTH"]
      callback_urls                = ["https://myapp.example.com/callback"]
      logout_urls                  = ["https://myapp.example.com/logout"]
    }
    token_validity = {
      refresh_token = 30
      access_token  = 6
      id_token      = 6
      refresh_unit  = "days"
      access_unit   = "hours"
      id_unit       = "hours"
    }
  }
}
```

## Variables

### General

| Variable | Type | Default | Description |
|---|---|---|---|
| `region` | `string` | `eu-west-1` | AWS region for deployment |
| `project_name` | `string` | `my-cognito-project` | Used for resource naming (3–20 chars, alphanumeric and hyphens) |
| `tags` | `map(string)` | See below | Common tags applied to all resources |

### User Pool

| Variable | Type | Description |
|---|---|---|
| `user_pool_settings` | `object` | Password policy, username attributes, verification, and schema |
| `managed_login_version` | `string` (`"1"` or `"2"`) | Cognito managed login UI version |

**`user_pool_settings` defaults:**

```hcl
{
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  password_policy = {
    min_length         = 8
    require_uppercase  = true
    require_lowercase  = true
    require_numbers    = true
    require_symbols    = true
    temp_validity_days = 7
  }
  user_pool_schema = [
    { name = "email", attribute_data_type = "String", mutable = false, required = true },
    { name = "role",  attribute_data_type = "String", mutable = false, required = false }
  ]
}
```

### App Client

| Variable | Type | Description |
|---|---|---|
| `cognito_client_config` | `object` | OAuth2 flows, scopes, callback/logout URLs, and token validity |

### Identity Providers

| Variable | Type | Default | Description |
|---|---|---|---|
| `idp_google` | `object` | disabled | Google OAuth2 IdP |
| `idp_facebook` | `object` | disabled | Facebook IdP |
| `idp_login_with_amazon` | `object` | disabled | Login with Amazon IdP |
| `idp_apple` | `object` | disabled | Sign in with Apple IdP (requires `team_id`, `key_id`, `private_key`) |
| `idp_oidc_providers` | `list(object)` | `[]` | One or more generic OIDC providers |
| `idp_saml_providers` | `list(object)` | `[]` | One or more SAML providers |

**OIDC provider object fields:**

| Field | Required | Description |
|---|---|---|
| `name` | yes | Unique provider name |
| `issuer` | yes | OIDC issuer URL |
| `client_id` | yes | Client ID |
| `client_secret` | yes | Client secret |
| `authorize_scopes` | no | Defaults to `openid profile email` |
| `attributes_request_method` | no | `GET` or `POST` (default `GET`) |
| `authorize_url` | no | Override authorization endpoint |
| `token_url` | no | Override token endpoint |
| `attributes_url` | no | Override userinfo endpoint |
| `jwks_uri` | no | Override JWKS URI |
| `attribute_mapping` | no | Custom attribute mapping |

**SAML provider object fields:**

| Field | Required | Description |
|---|---|---|
| `name` | yes | Unique provider name |
| `metadata_url` | yes* | SAML metadata URL |
| `metadata_file` | yes* | SAML metadata file (alternative to `metadata_url`) |
| `idp_init` | no | IdP-initiated sign-on (`"true"` / `"false"`) |
| `encrypted_responses` | no | Require encrypted assertions |
| `idp_signout` | no | Enable IdP-initiated sign-out |
| `request_signing_algorithm` | no | Defaults to `rsa-sha256` |
| `attribute_mapping` | no | Custom attribute mapping |

\* Either `metadata_url` or `metadata_file` is required.

## Notes

- **No client secret** — `generate_secret` must be `false` (enforced by validation). Use PKCE for public clients.
- **Schema changes** — `ignore_changes = [schema]` is set on the user pool to avoid in-place schema update errors after initial creation.
- **Supported IdPs** — the client's `supported_identity_providers` list is computed automatically from whichever IdPs are enabled; `COGNITO` is always included if present in the variable.
- **Domain naming** — the hosted UI domain follows the pattern `{project_name}-{aws_account_id}-domain` to ensure global uniqueness.

## Deployment

```bash
terraform init
terraform plan
terraform apply
```
