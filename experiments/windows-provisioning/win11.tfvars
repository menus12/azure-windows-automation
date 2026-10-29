# Windows 11 Pro 26H2 from the Marketplace, the version fixed for the experiments.
# Requires an eligible Windows 11 license for the users (Multitenant Hosting Rights).
image = {
  publisher = "MicrosoftWindowsDesktop"
  offer     = "windows-11"
  sku       = "win11-26h2-pro"
}
license_type = "Windows_Client"

# Standard_B2s and the Dsv5/Dasv5/Bsv2 sizes are not available to the PoC subscription
# in westeurope; Dsv7 is. Dsv7 runs only with an NVMe disk controller.
vm_size              = "Standard_D2s_v7"
disk_controller_type = "NVMe"

trusted_launch = true
name_prefix    = "awa-poc-cfgtest-w11"
