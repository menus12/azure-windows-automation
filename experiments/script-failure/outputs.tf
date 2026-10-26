output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "run_command_instance_views" {
  value = { for k, v in azurerm_virtual_machine_run_command.this : k => v.instance_view }
}
