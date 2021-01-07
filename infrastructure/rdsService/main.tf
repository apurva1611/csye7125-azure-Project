## Azure resource provider ##
provider "azurerm" {
  version = "~>2.0"
  features {}
}

## Azure terraform backend
terraform {
  backend "azurerm" {
    resource_group_name   = "aks-csye7125-rg"
    storage_account_name  = "tfstatesecsyeproject"
    container_name        = "tfstates"
    key                   = "dbService/tfstate"
  }
}

resource "azurerm_virtual_network" "azure_mysql_vnet" {
  name                = "azure_mysql_vnet"
  address_space       = ["172.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "azure_mysql_subnet" {
  name                 = "azure_mysql_subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_mysql_vnet.name
  address_prefixes     = ["172.0.0.0/24"]
  service_endpoints    = ["Microsoft.Sql"]

  delegation {
    name = "mydelegation"

    service_delegation {
      name    = "Microsoft.DBforMySQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule1" {
  name                = var.networkrule_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.webapp_db.name
  subnet_id           = var.subnet_id
}

resource "azurerm_mysql_firewall_rule" "demo-allow-demo-instance" {
  name                = var.webapp_db
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.webapp_db.name
  start_ip_address    = var.private_start_ip_address
  end_ip_address      = var.private_end_ip_address
  ##https://docs.microsoft.com/en-us/azure/azure-sql/database/network-access-controls-overview
}

/*
# resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnet_rule_poller" {
#   name                = "azure_mysql_vnet_rule_poller"
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.poller_db.name
#   subnet_id           = azurerm_subnet.azure_mysql_subnet.id
# }

# resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnet_rule_notifier" {
#   name                = "azure_mysql_vnet_rule_notifier"
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.notifier_db.name
#   subnet_id           = azurerm_subnet.azure_mysql_subnet.id
# }
*/

resource "azurerm_mysql_server" "webapp_db" {
  name                  = var.webapp_db
  location              = var.location
  resource_group_name   = var.resource_group_name

  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup

  administrator_login           = var.admin_username
  administrator_login_password  = var.admin_password
  version                       = var.db_version
  ssl_enforcement_enabled       = var.ssl_enforcement
}

resource "azurerm_mysql_database" "webappdb" {
  name                = "webappdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.webapp_db.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# resource "azurerm_virtual_network_peering" "aks-to-db-peering" {
#   name                         = "aks-to-db-peering"
#   resource_group_name          = var.resource_group_name
#   virtual_network_name         = azurerm_virtual_network.azure_mysql_vnet.name
#   remote_virtual_network_id    = azurerm_virtual_network.example-2.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = false
#   allow_gateway_transit        = false
# }

# resource "azurerm_virtual_network_peering" "db-to-aks-peering" {
#   name                         = "db-to-aks-peering"
#   resource_group_name          = var.resource_group_name
#   virtual_network_name         = azurerm_virtual_network.azure_mysql_vnet.name
#   remote_virtual_network_id    = azurerm_virtual_network.example-2.id
#   allow_virtual_network_access = true
#   allow_forwarded_traffic      = false
#   allow_gateway_transit        = false
# }
/*
resource "azurerm_mysql_server" "poller_db" {
  name                  = var.poller_db
  location              = var.location
  resource_group_name   = var.resource_group_name

  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup

  administrator_login           = "polleruser"
  administrator_login_password  = "Pass1234"
  databases_names               = ["pollerdb"]
  version                       = var.db_version
  ssl_enforcement_enabled       = var.ssl_enforcement
}

resource "azurerm_mysql_server" "notifier_db" {
  name                  = var.notifier_db
  location              = var.location
  resource_group_name   = var.resource_group_name

  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup

  administrator_login           = "notifieruser"
  administrator_login_password  = "Pass1234"
  databases_names               = ["notifierdb"]
  version                       = var.db_version
  ssl_enforcement_enabled       = var.ssl_enforcement
}
*/