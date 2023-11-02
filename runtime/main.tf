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
  client_id          = "865fb1ad-a952-481a-94a3-e97bcadc84d0"
  oidc_request_url   = "https://hp.geuer-pollmann.de:3000/issue"
  oidc_request_token = "secret"
  features {
  }
}

# GET /issue?audience=api%3A%2F%2FAzureADTokenExchange HTTP/1.1
# Host: hp.geuer-pollmann.de:3000
# User-Agent: Go-http-client/1.1
# Accept: application/json
# Authorization: Bearer secret
# Content-Type: application/x-www-form-urlencoded
# Accept-Encoding: gzip

resource "azurerm_resource_group" "example" {
  name     = "qdrantsample"
  location = "West Europe"
}

resource "azurerm_storage_account" "example" {
  name                     = "chgpqdrant"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "staging"
  }
}