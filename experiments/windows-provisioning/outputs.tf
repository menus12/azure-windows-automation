output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.this.name
}

output "run_command_instance_view" {
  value = azurerm_virtual_machine_run_command.install_pwsh.instance_view
}
