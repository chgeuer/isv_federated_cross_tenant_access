# Demo

[![Deploy To Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fchgeuer%2Fisv_federated_cross_tenant_access%2Fmain%2Fmain.json)



## Simulate web server to see Terraform's request

```shell
cd /home/chgeuer/.lego/certificates/
cat hp.geuer-pollmann.de.key hp.geuer-pollmann.de.crt > hp.geuer-pollmann.de.pem
socat openssl-listen:3000,reuseaddr,cert=/home/chgeuer/.lego/certificates/hp.geuer-pollmann.de.pem,verify=0,fork stdio
curl --include https://hp.geuer-pollmann.de:3000/
```

## Configure Terraform to call into a custom IdP for federated sign-in

```terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.77.0"
    }
  }
}

provider "azurerm" {
  tenant_id          = "chgeuerfte.aad.geuer-pollmann.de"
  subscription_id    = "724467b5-bee4-484b-bf13-d6a5505d2b51"

  use_oidc           = true
  client_id          = "00000000-0000-0000-0000-000000000000"
  oidc_request_url   = "https://hp.geuer-pollmann.de:3000/issue"
  oidc_request_token = "secret"
  features {
  }
}
```

This makes Terraform ask the 'local' IdP for an access token:

```http
GET /issue?audience=api%3A%2F%2FAzureADTokenExchange HTTP/1.1
Host: hp.geuer-pollmann.de:3000
Authorization: Bearer secret
User-Agent: Go-http-client/1.1
Accept: application/json
Accept-Encoding: gzip
Content-Type: application/x-www-form-urlencoded

```

## Links

- [Deploy resources to multiple scopes](https://learn.microsoft.com/en-us/training/modules/deploy-resources-scopes-bicep/5-deploy-multiple-scopes?pivots=cli)
cd 

