variable "aks_rg" {
  description = "(Required) Name of the resource group where to create the aks"
  type        = string
  default = "mtcaks-rg"
}

variable "name" {
  description = "(Required) The name of the Managed Kubernetes Cluster to create."
  type        = string
  default = "mt-aks"
}

variable "virtual_network_name" {
  description = "Name for the Azure Virtual Network"
  type        = string
  default     = "mtc-vnet"
}

variable "subnet_name" {
  description = "Name for the Azure Subnet"
  type        = string
  default     = "mtcsubnet"
}

variable "vpn_gateway_name" {
  description = "Name for the Azure VPN Gateway"
  type        = string
  default     = "mtcaksvpngatewy"
}

variable "location" {
  description = "(Required) Define the region where the resource groups will be created"
  type        = string
  default     = "East US"
}

variable "kubernetes_version" {
  description = "(Optional) Version of Kubernetes specified when creating the AKS managed cluster"
  default     = ""
}

variable "network_profile" {
  description = "(Optional) Sets up network profile for Advanced Networking."
  default = {
    # Use azure-cni for advanced networking
    network_plugin = "azure"
    # Sets up network policy to be used with Azure CNI. Currently supported values are calico and azure."
    #network_policy     = "azure"
    #service_cidr       = "10.100.0.0/16"
    #dns_service_ip     = "10.100.0.10"
    #docker_bridge_cidr = "172.17.0.1/16"
    # Specifies the SKU of the Load Balancer used for this Kubernetes Cluster. Use standard for when enable agent_pools availability_zones.
    load_balancer_sku = "standard"
  }
}


