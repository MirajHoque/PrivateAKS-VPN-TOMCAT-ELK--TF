terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.93.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.12.1"
    }
  }
  
}

provider "azurerm" {
  # Configuration options
  features {}
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

#client configuration
data "azurerm_client_config" "current" {}

#resource group
resource "azurerm_resource_group" "aks_rg" {
  name     = var.aks_rg
  location = var.location
}

#Virtual Network
resource "azurerm_virtual_network" "mt_vnet" {
  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = var.aks_rg
  address_space       = ["172.16.0.0/16"]

  depends_on = [
    azurerm_resource_group.aks_rg
  ]
}

#Subnet
resource "azurerm_subnet" "mt_subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.aks_rg
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["172.16.0.0/24"]

  depends_on = [
    azurerm_resource_group.aks_rg,
    azurerm_virtual_network.mt_vnet
  ]
}

#Gateway Subnet
resource "azurerm_subnet" "mt_gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.aks_rg
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["172.16.1.0/24"]

  depends_on = [
    azurerm_resource_group.aks_rg,
    azurerm_virtual_network.mt_vnet
  ]
}

#public ip
resource "azurerm_public_ip" "mypublicendpoint" {
  name                = "mypublicendpoint"
  location            = var.location
  resource_group_name = var.aks_rg
  allocation_method   = "Dynamic"

  depends_on = [
    azurerm_resource_group.aks_rg,
  ]
}

#virtual network gateway
resource "azurerm_virtual_network_gateway" "myaksvpngatewy" {
  name                = var.vpn_gateway_name
  resource_group_name = var.aks_rg
  location            = var.location

  type                = "Vpn"
  vpn_type            = "RouteBased"

  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"

  ip_configuration {
    name                          = "gatewayConfiguration"
    subnet_id                     = azurerm_subnet.mt_gateway_subnet.id
    public_ip_address_id          = azurerm_public_ip.mypublicendpoint.id
    private_ip_address_allocation = "Dynamic"
  }

  vpn_client_configuration {
    address_space        = ["10.2.0.0/24"]
    vpn_client_protocols = ["SSTP"]
    vpn_auth_types       = ["Certificate"]

    root_certificate {
      name                 = "DigiCert-Federated-ID-Root-CA"
      
      public_cert_data = <<EOF
MIIC9TCCAd2gAwIBAgIQdi0/cRfMgLJMhKzrb+XWbzANBgkqhkiG9w0BAQsFADAd
MRswGQYDVQQDDBJOYW1lb2Z5b3VyUm9vdENlcnQwHhcNMjQwMjI0MjAzNDA0WhcN
MjUwMjI0MjA1NDA0WjAdMRswGQYDVQQDDBJOYW1lb2Z5b3VyUm9vdENlcnQwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDN/KvKl0/0EzNwtQhX/rtIwZfY
zhEKJDbT/Pu+eRrRALEwsNurqxWSQxB1B5b3GWMJtz1q89d2fv9XGMYVYuzFK/YO
i+E8GI5WiWkjIOolycpdcED0CruUrvJPMtdqW4EBiDhdrwy/AgxJ8efS5Xzpn0It
lhH/IyVtOjK6kBGTDC04Y05nuzmc746vGwyAzLasZvVGg7X7l2qMh72PsgjA0OB/
50GDrIHPXbT5bknEk1J6HmbJd5/T1y93D49Op8BxDBzfqlZxTVdYiMQbMdmmc7yn
6R6jXahKRfcc0xlCe8YEQg1k4Kh0rlx88nZkTYlvH6PhTV5iFgtzBnf7o089AgMB
AAGjMTAvMA4GA1UdDwEB/wQEAwICBDAdBgNVHQ4EFgQUd2Gb0DPqj/MGwMdkBjTu
T+wPruAwDQYJKoZIhvcNAQELBQADggEBAFShRcpJcdXFiHcmA10B5f4hFTi52HYB
3m2avWEsh6g46DxGWw/EeP5XrEM/2ese62a2FV9AOqEUfh9Xh4vsRuOoSi7nnHu+
R9sOmviGAlxl891NHbKMI6e0RJTJ+SmJ8ASz9nhI2D+UEQQiERlGAVzJiHs8+Cis
LtqNPm+vuYGHiPaH4QDrQmFYmmb8L7yquq/HuQRjJZVQ93/SOAU/R7pELac1+7k8
EylfBUw2nGtB96y9v1yq+Y9XOnLK1O7dIR6UTg8S15qZLBS46gJela8smQE5csrO
D0SY5hMVpt9BhLxMT6ASQCUL5Yn4cUSekELuyV1hG14NsEByyAZW7Ys=
EOF

    }
  }

  depends_on = [
    azurerm_resource_group.aks_rg,
    azurerm_subnet.mt_gateway_subnet
  ]
}

#creating k8s cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  dns_prefix          = var.name
  resource_group_name = var.aks_rg
  location            = var.location

  private_cluster_enabled = true
  private_cluster_public_fqdn_enabled = true

  network_profile {
    network_plugin     = var.network_profile.network_plugin
    load_balancer_sku  = lookup(var.network_profile, "load_balancer_sku", "basic")
    #lookup(): retrieve the value of a specified key from a map or a list.
  }


  #retrieve the latest version of Kubernetes supported by Azure Kubernetes Service if version is not set
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : data.azurerm_kubernetes_service_versions.current.latest_version

   default_node_pool {
    name       = "workernodes"
    vm_size    = "Standard_B2s"
    # max_count            = 3
    # min_count            = 2
    node_count = 2
    os_disk_size_gb      = 30
    vnet_subnet_id = azurerm_subnet.mt_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    azurerm_resource_group.aks_rg,
    azurerm_virtual_network.mt_vnet
  ]
}
