# 1. Resource Groups
module "rg" {
  source = "github.com/aortizorexe/azure-modules//azure-resource-group?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  resource_groups = {
    "rg-opella-network-001" = {}
    "rg-opella-storage-001" = {}
    "rg-opella-compute-001" = {}
  }
}

# 2. VNet and Subnets
module "vnet" {
  source = "github.com/aortizorexe/azure-modules//azure-vnet?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  vnets = {
    "vnet-opella-001" = {
      resource_group_name = module.rg.resource_group_names["rg-opella-network-001"]
      address_space       = ["10.0.0.0/16"]
      subnets = {
        "snet-app-001" = {
          address_prefixes = ["10.0.1.0/24"]
        }
        "snet-storage-001" = {
          address_prefixes  = ["10.0.2.0/24"]
          service_endpoints = ["Microsoft.Storage"]
        }
      }
    }
  }
}

# 3. Route Table
module "route_table" {
  source = "github.com/aortizorexe/azure-modules//azure-route-table?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  route_tables = {
    "rt-opella-app-001" = {
      resource_group_name           = module.rg.resource_group_names["rg-opella-network-001"]
      bgp_route_propagation_enabled = false

      routes = {
        "to-internet" = {
          address_prefix = "0.0.0.0/0"
          next_hop_type  = "Internet"
        }
      }
      subnet_ids = {
        "snet-app" = module.vnet.subnet_ids["vnet-opella-001.snet-app-001"]
      }
    }
  }
}

# 4. Storage Account
module "storage" {
  source = "github.com/aortizorexe/azure-modules//azure-storage-account?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  storage_accounts = {
    "stopellablob001" = {
      resource_group_name           = module.rg.resource_group_names["rg-opella-storage-001"]
      account_tier                  = "Standard"
      account_replication_type      = "LRS"
      public_network_access_enabled = true

      network_rules = {
        default_action = "Deny"
        virtual_network_subnet_ids = [
          module.vnet.subnet_ids["vnet-opella-001.snet-storage-001"]
        ]
      }
    }
  }
}

# 5. Network Interface
module "nic" {
  source = "github.com/aortizorexe/azure-modules//azure-nic?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  nics = {
    "nic-opella-web-001" = {
      resource_group_name = module.rg.resource_group_names["rg-opella-compute-001"]
      ip_configurations = {
        "ipconfig1" = {
          subnet_id                     = module.vnet.subnet_ids["vnet-opella-001.snet-app-001"]
          private_ip_address_allocation = "Dynamic"
          primary                       = true
        }
      }
    }
  }
}

# 6. Virtual Machine
module "vm" {
  source = "github.com/aortizorexe/azure-modules//azure-vm-windows?ref=v1.0.0"

  location       = var.location
  tags_mandatory = var.tags_mandatory

  vms = {
    "vm-opella-web" = {
      resource_group_name = module.rg.resource_group_names["rg-opella-compute-001"]
      size                = "Standard_D2s_v3"
      admin_username      = "adminopella"
      admin_password      = var.vm_admin_password

      network_interface_ids = [
        module.nic.nic_ids["nic-opella-web-001"]
      ]

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
        disk_size_gb         = 128
      }

      source_image_reference = {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
      }
    }
  }
}