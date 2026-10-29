# Experiment: which deploy-time configuration mechanisms actually run on a
# Windows VM in Azure. See README.md in this directory for the test matrix.

locals {
  tags = {
    project   = "azure-windows-automation"
    purpose   = "poc-windows-provisioning-test"
    ephemeral = "true"
  }
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
  address_space       = ["10.42.0.0/24"]
  tags                = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = "snet-vm"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.42.0.0/26"]
}

# No inbound allow rules: the default rules deny all inbound traffic from the
# internet. The VM is inspected through Run Command, not RDP.
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

# Public IP for explicit outbound internet access (package downloads).
resource "azurerm_public_ip" "this" {
  name                = "pip-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "this" {
  name                = "nic-${var.name_prefix}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = local.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
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
  name                  = "vm-cfgtest"
  computer_name         = "cfgtest"
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  size                  = var.vm_size
  disk_controller_type  = var.disk_controller_type
  admin_username        = "azureadmin"
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.this.id]
  license_type          = var.license_type
  secure_boot_enabled   = var.trusted_launch
  vtpm_enabled          = var.trusted_launch
  tags                  = local.tags

  # Test A: custom data. Expected to land in C:\AzureData\CustomData.bin
  # without being executed.
  custom_data = base64encode(file("${path.module}/scripts/customdata.ps1"))

  # Test B: user data. Expected to be readable from IMDS, not executed.
  user_data = base64encode(file("${path.module}/scripts/userdata.ps1"))

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

# Test C: Custom Script Extension that executes the custom data payload.
# The wrapper is passed as -EncodedCommand to avoid quoting issues.
resource "azurerm_virtual_machine_extension" "customdata_runner" {
  name                       = "customdata-runner"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  protected_settings = jsonencode({
    commandToExecute = "powershell.exe -NoProfile -ExecutionPolicy Bypass -EncodedCommand ${textencodebase64(file("${path.module}/scripts/cse-wrapper.ps1"), "UTF-16LE")}"
  })
}

# Test D: Managed Run Command with an inline script.
resource "azurerm_virtual_machine_run_command" "install_pwsh" {
  name               = "install-pwsh7"
  location           = azurerm_resource_group.this.location
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  tags               = local.tags

  source {
    script = file("${path.module}/scripts/runcommand.ps1")
  }

  # Run after the extension so the two agents' handlers don't compete.
  depends_on = [azurerm_virtual_machine_extension.customdata_runner]
}
