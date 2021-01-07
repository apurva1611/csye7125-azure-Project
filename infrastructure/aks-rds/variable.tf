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

variable "admin_cluster_username" {
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

## database variable
variable "webapp_instance" {
 
}

variable "poller_instance" {
 
}

variable "notifier_instance" {
 
}

variable "sku_name" {
 
}

variable "storage_mb" {
 
}

variable "backup_retention_days" {
 
}

variable "geo_redundant_backup" {
 
}

variable "admin_username" {
 
}

variable "admin_password" {
 
}

variable "db_version" {
 
}

variable "ssl_enforcement" {
 
}

variable "networkrule_name" {
 
}

variable "private_start_ip_address" {
 
}

variable "private_end_ip_address" {
 
}

variable "subnet_id" {
 
}