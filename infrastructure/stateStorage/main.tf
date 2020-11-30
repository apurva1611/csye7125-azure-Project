## Azure resource provider ##
provider "azurerm" {
  version = "~>2.0"
  features {}
}

## Azure terraform backend
# terraform {
#   backend "azurerm" {
#     resource_group_name   = "aks-csye7125-rg"
#     storage_account_name  = "tfstatesecsyeproject"
#     container_name        = "tfstates"
#     key                   = "storage/tfstate"
#   }
# }

resource "azurerm_storage_account" "terraform_backend_storage" {
  name                      = "tfstatesecsyeproject"
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  enable_https_traffic_only = true
}

resource "azurerm_storage_container" "terraform_backendcontainer" {
  name                  = "tfstates"
  storage_account_name  = azurerm_storage_account.terraform_backend_storage.name
  container_access_type = "private"

  #waiting for Storage Soft Delete Support #1070
}

output "resource_group_name" {
  description = "Resource group value to use to configure backends"
  value       = var.resource_group_name
}

output "storageaccount-for-tfstates" {
  description = "Storage account value to use to configure backends"
  value       = azurerm_storage_account.terraform_backend_storage.name
}

output "container-for-tfstates" {
  description = "Container value to use to configure backends"
  value       = azurerm_storage_container.terraform_backendcontainer.name
}
