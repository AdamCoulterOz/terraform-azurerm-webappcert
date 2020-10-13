terraform {
  required_version = ">= 0.13"
  required_providers {
    shell = {
      source  = "scottwinkler/shell"
      version = "~>1.7"
    }
  }
}


provider "shell" {
  environment = {
    AzureClientId     = var.client_id
    AzureTenantId     = var.tenant_id
    AzureSubscription = var.subscription_id
  }

  sensitive_environment = {
    AzureClientSecret = var.client_secret
  }

  interpreter = ["pwsh", "-Command"]
}