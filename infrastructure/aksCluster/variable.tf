## Azure config variables ##
variable "location" {
  default = "East US"
}

## Resource group variables ##
variable "resource_group_name" {
 
}

## AKS kubernetes cluster variables ##
variable "cluster_name" {

}

variable "agent_count" {
  default = 3
}

variable "dns_prefix" {
  default = "cluster.prod.achirashah.com"
}

variable "admin_username" {
    default = "azureuser"
}

variable "public_ssh_key" {
  description = "An ssh key set in the main variables of the terraform-azurerm-aks module"
  default     = ""
}

variable "vm_size"{
    default = "Standard_D2_v2"
}

variable "os_disk_size_gb"{
    default = 30
}

variable "ipspace"{
    default = "10.0.0.0/16"
}

variable "default_tags"{
    default = "k8s-cluster"
}

variable "sshpubkey"{
    default = "~/.ssh/id_rsa.pub"
}

variable "vmsubnet"{

}

variable "akspodssubnet"{

}

variable "k8s_version"{

}

variable "node_resource_group_name"{

}