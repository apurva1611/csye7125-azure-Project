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
#     key                   = "resource/tfstate"
#   }
# }

## Azure resource group for the kubernetes cluster ##
resource "azurerm_resource_group" "aks_csye7125_rg" {
  name     = var.resource_group_name
  location = var.location
}

output "resource_group_name" {
  description = "Resource group value to use to configure backends"
  value       = azurerm_resource_group.aks_csye7125_rg.name
}
