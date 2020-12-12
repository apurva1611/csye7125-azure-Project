## Azure resource provider ##
provider "azurerm" {
  version = "~>2.0"
  features {}
}

## Azure terraform backend
terraform {
  backend "azurerm" {
    resource_group_name   = "aks-csye7125-rg"
    storage_account_name  = "tfstatesecsyeprojectterm"
    container_name        = "tfstates"
    key                   = "rds-cluster/tfstate"
  }
}

resource "azurerm_virtual_network" "azure_aks_vnet" {
  name                = "azure_aks_vnet"
  address_space       = ["10.0.0.0/8"]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "azure_aks_subnet" {
  name                 = "azure-aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.azure_aks_vnet.name
  address_prefixes     = ["10.240.0.0/16"]
  service_endpoints    = ["Microsoft.Sql"]
#   ignore_missing_vnet_service_endpoint = true
}

## AKS kubernetes cluster ##
resource "azurerm_kubernetes_cluster" "aks_csye7125_cluster" { 
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  node_resource_group = var.node_resource_group_name
  kubernetes_version  = var.k8s_version
  private_cluster_enabled = false
  linux_profile {
    admin_username = var.admin_cluster_username

    ## SSH key is generated using "tls_private_key" resource
    ssh_key {
      key_data = "${trimspace(tls_private_key.key.public_key_openssh)} ${var.admin_username}@azure.com"
    }
  }

  default_node_pool {
    name                  = "default"
    node_count            = var.agent_count
    vm_size               = var.vm_size
    enable_node_public_ip = false
    vnet_subnet_id        = azurerm_subnet.azure_aks_subnet.id
  }

  addon_profile {
    aci_connector_linux {
      enabled = false
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = true
    }

    oms_agent {
      enabled = false
    }
  }

  identity {
    type = "SystemAssigned"
  }

}

# Private key for the kubernetes cluster ##
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Save the private key in the local workspace ##
resource "null_resource" "save-key" {
  triggers = {
    key = tls_private_key.key.private_key_pem
  }

  provisioner "local-exec" {

    command = <<EOF
      mkdir -p ${path.module}/.ssh  
      echo "${tls_private_key.key.private_key_pem}" > ${path.module}/.ssh/myKeyPair
      chmod 0600 ${path.module}/.ssh/myKeyPair
EOF
  }
}

# create mysql
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

# resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_webapp" {
#   name                = var.networkrule_name
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.webapp_instance.name
#   subnet_id           = azurerm_subnet.azure_mysql_subnet.id
# }

# resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_poller" {
#   name                = var.networkrule_name
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.poller_instance.name
#   subnet_id           = azurerm_subnet.azure_mysql_subnet.id
# }

# resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_notifer" {
#   name                = var.networkrule_name
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.notifier_instance.name
#   subnet_id           = azurerm_subnet.azure_mysql_subnet.id
# }

resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_aks1" {
  name                = var.networkrule_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.webapp_instance.name
  subnet_id           = azurerm_subnet.azure_aks_subnet.id
  depends_on          = [azurerm_subnet.azure_aks_subnet]
}

resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_aks2" {
  name                = var.networkrule_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.poller_instance.name
  subnet_id           = azurerm_subnet.azure_aks_subnet.id
  depends_on          = [azurerm_subnet.azure_aks_subnet]
}

resource "azurerm_mysql_virtual_network_rule" "azure_mysql_vnetrule_aks3" {
  name                = var.networkrule_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.notifier_instance.name
  subnet_id           = azurerm_subnet.azure_aks_subnet.id
  depends_on          = [azurerm_subnet.azure_aks_subnet]
}

# resource "azurerm_mysql_firewall_rule" "demo-allow-demo-instance" {
#   name                = var.webapp_db
#   resource_group_name = var.resource_group_name
#   server_name         = azurerm_mysql_server.webapp_db.name
#   start_ip_address    = var.private_start_ip_address
#   end_ip_address      = var.private_end_ip_address
#   ##https://docs.microsoft.com/en-us/azure/azure-sql/database/network-access-controls-overview
# }

resource "azurerm_mysql_server" "webapp_instance" {
  name                  = var.webapp_instance
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
  server_name         = azurerm_mysql_server.webapp_instance.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_server" "poller_instance" {
  name                  = var.poller_instance
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

resource "azurerm_mysql_database" "pollerdb" {
  name                = "pollerdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.poller_instance.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

resource "azurerm_mysql_server" "notifier_instance" {
  name                  = var.notifier_instance
  location              = var.location
  resource_group_name   = var.resource_group_name

  sku_name                      = var.sku_name
  storage_mb                    = var.storage_mb
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup

  administrator_login           = "adminuser"
  administrator_login_password  = var.admin_password
  version                       = var.db_version
  ssl_enforcement_enabled       = var.ssl_enforcement
}

resource "azurerm_mysql_database" "notifierdb" {
  name                = "notifierdb"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.notifier_instance.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}

# ## Outputs ##

# # Example attributes available for output
output "vnet_id" {
    value = azurerm_virtual_network.azure_aks_vnet.id
}

output "subnet_id" {
  value = azurerm_subnet.azure_aks_subnet.id
}

output "id" {
    value = azurerm_kubernetes_cluster.aks_csye7125_cluster.id
}

output "client_key" {
  value = azurerm_kubernetes_cluster.aks_csye7125_cluster.kube_config.0.client_key
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.aks_csye7125_cluster.kube_config.0.client_certificate
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.aks_csye7125_cluster.kube_config.0.cluster_ca_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.aks_csye7125_cluster.kube_config_raw
}

output "host" {
  value = azurerm_kubernetes_cluster.aks_csye7125_cluster.kube_config.0.host
}

output "configure" {
  value = <<CONFIGURE
Run the following commands to configure kubernetes client:
$ terraform output kube_config > ~/.kube/aksconfig
$ export KUBECONFIG=~/.kube/aksconfig
Test configuration using kubectl
$ kubectl get nodes
CONFIGURE
}