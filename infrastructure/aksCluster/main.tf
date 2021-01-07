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
    key                   = "cluster/tfstate"
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
    admin_username = var.admin_username

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

#   dynamic service_principal {
#     for_each = var.client_id != "" && var.client_secret != "" ? ["service_principal"] : []
#     content {
#       client_id     = var.client_id
#       client_secret = var.client_secret
#     }
#   }

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

  # tags = {
  #   Environment = "production"
  # }
}

# resource "azurerm_kubernetes_cluster_node_pool" "aks_node_pool" {
#   name                  = "internal"
#   kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_csye7125_cluster.id
#   vm_size               = "Standard_DS2_v2"
#   node_count            = 1
#   vnet_subnet_id        = azurerm_subnet.azure_aks_subnet.id
# }

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