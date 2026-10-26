# Experiment: how terraform apply reacts when a deploy-time script fails.
# One VM per case, because a VM can carry only one Custom Script Extension.
# See README.md in this directory for the test matrix.

locals {
  tags = {
    project   = "azure-windows-automation"
    purpose   = "poc-script-failure-test"
    ephemeral = "true"
  }

  cases = {
    "cse-throw" = { mechanism = "cse", script = "fail-throw.ps1" }
    "cse-soft"  = { mechanism = "cse", script = "fail-soft.ps1" }
    "rc-throw"  = { mechanism = "rc", script = "fail-throw.ps1" }
    "rc-soft"   = { mechanism = "rc", script = "fail-soft.ps1" }
  }

  cse_cases = { for k, v in local.cases : k => v if v.mechanism == "cse" }
  rc_cases  = { for k, v in local.cases : k => v if v.mechanism == "rc" }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.43.0.0/24"]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.43.0.0/26"]
}

# No inbound allow rules; VMs are inspected through Run Command.
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_public_ip" "this" {
  for_each = local.cases

  name                = "pip-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  for_each = local.cases

  name                = "nic-${each.key}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this[each.key].id
  }
}

resource "random_password" "admin" {
  length      = 24
  special     = true
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  min_special = 1
}

resource "azurerm_windows_virtual_machine" "this" {
  for_each = local.cases

  name                  = "vm-${each.key}"
  computer_name         = each.key
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  admin_username        = "azureadmin"
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.this[each.key].id]
  license_type          = var.license_type
  secure_boot_enabled   = var.trusted_launch
  vtpm_enabled          = var.trusted_launch
  tags                  = local.tags

  # Custom Script Extension cases carry their payload as custom data.
  custom_data = each.value.mechanism == "cse" ? base64encode(file("${path.module}/scripts/${each.value.script}")) : null

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.image.publisher
    offer     = var.image.offer
    sku       = var.image.sku
    version   = "latest"
  }

  boot_diagnostics {}
}

resource "azurerm_virtual_machine_extension" "this" {
  for_each = local.cse_cases

  name                       = "run-customdata"
  virtual_machine_id         = azurerm_windows_virtual_machine.this[each.key].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(file("${path.module}/scripts/cse-wrapper.ps1"), "UTF-16LE")}"
  })
}

resource "azurerm_virtual_machine_run_command" "this" {
  for_each = local.rc_cases

  name               = "run-script"
  location           = azurerm_resource_group.this.location
  virtual_machine_id = azurerm_windows_virtual_machine.this[each.key].id
  tags               = local.tags

  source {
    script = file("${path.module}/scripts/${each.value.script}")
  }
}
