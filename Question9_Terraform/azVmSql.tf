provider "azurerm" {
  version = "=2.20.0"
  features {}
}
variable "prefix" {
  default = "azvm"
}

resource "azurerm_resource_group" "azrg" {
  name     = "${var.prefix}-resources"
  location = "West US 2"
}

resource "azurerm_virtual_network" "azvnet" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azrg.location
  resource_group_name = azurerm_resource_group.azrg.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.azrg.name
  virtual_network_name = azurerm_virtual_network.azvnet.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "publicIp" {
  name                    = "az-pip"
  location                = azurerm_resource_group.azrg.location
  resource_group_name     = azurerm_resource_group.azrg.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30

}

resource "azurerm_network_interface" "azNic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.azrg.location
  resource_group_name = azurerm_resource_group.azrg.name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.5"
    public_ip_address_id          = azurerm_public_ip.publicIp.id


  }
}

resource "azurerm_virtual_machine" "azVm" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.azrg.location
  resource_group_name   = azurerm_resource_group.azrg.name
  network_interface_ids = [azurerm_network_interface.azNic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "azVm"
    admin_username = "azadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "azurerm_postgresql_server" "postgresql" {
  name                = "postgresql-db-server-1"
  location            = azurerm_resource_group.azrg.location
  resource_group_name = azurerm_resource_group.azrg.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "postgresa"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}

resource "azurerm_postgresql_database" "postgresqldb" {
  name                = "postgresqldb"
  resource_group_name = azurerm_resource_group.azrg.name
  server_name         = azurerm_postgresql_server.postgresql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_postgresql_firewall_rule" "azFirewall" {
  name                = "azFirewallRule"
  resource_group_name = azurerm_resource_group.azrg.name
  server_name         = azurerm_postgresql_server.postgresql.name
  start_ip_address    = "10.0.2.4"
  end_ip_address      = "10.0.2.254"
}