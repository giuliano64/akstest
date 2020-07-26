resource "azurerm_resource_group" "postgresql" {
  name     = "postgresql-rg"
  location = "West Europe"
}

resource "azurerm_postgresql_server" "postgresql" {
  name                = "postgresql-db-server-1"
  location            = azurerm_resource_group.postgresql.location
  resource_group_name = azurerm_resource_group.postgresql.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladminun"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_database" "postgresql" {
  name                = "postgresqldb"
  resource_group_name = azurerm_resource_group.postgresql.name
  server_name         = azurerm_postgresql_server.postgresql.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}