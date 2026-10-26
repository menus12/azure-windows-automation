# Technical Reference

## What this project is

`azure-windows-automation` is a proof of concept for automating the deployment of Windows-based
virtual machines in Microsoft Azure. The deployment covers both layers:

- **Infrastructure** — the Azure resources a VM needs (resource group, virtual network, subnet,
  network security group, public IP / NIC, disks, the VM itself).
- **Guest configuration** — what happens inside the Windows OS after the VM boots.

Design goal: **a deployment is code.** Nothing required to reproduce an environment is done by
hand in the Azure portal.

## Components

_TBD — filled in as components are built._

| Component | Runs where | Responsibility |
|-----------|-----------|----------------|
| | | |

## Guest configuration

Windows VMs in Azure have no cloud-init: custom data and user data are delivered to the VM but
never executed ([research](research/windows-provisioning.md)). Deploy-time configuration runs
through the VM Agent instead:

- **Custom Script Extension** (`azurerm_virtual_machine_extension`) — the payload travels as
  custom data and the extension executes `C:\AzureData\CustomData.bin`.
- **Managed Run Command** (`azurerm_virtual_machine_run_command`) — inline scripts, several per
  VM, output in the resource's `instance_view`.

Both behave the same on Windows Server 2022 and Windows 11. Which one is the default is an open
decision. Either way, scripts run as `LocalSystem`, must be idempotent, must not restart the VM,
and use `Invoke-WebRequest -UseBasicParsing`.

Scripts must fail loudly ([research](research/script-failure.md)): `$ErrorActionPreference =
"Stop"`, an exit code check after every native command, and a non-zero exit on failure. Azure and
Terraform only see the exit code. A failed extension or run command stays in Azure outside the
Terraform state and has to be deleted (or the VM recreated) before a retry.

## Windows 11

Test VMs run Windows 11 Enterprise from the Marketplace ([research](research/windows-client.md)):
`license_type = "Windows_Client"` and Trusted Launch (`secure_boot_enabled`, `vtpm_enabled`).

## Naming

### Azure resources

_TBD — naming scheme for resource groups, VMs, networks, and other resources._

Experiments use the prefix `awa-poc-` (for example `rg-awa-poc-cfgtest`) and carry the tags
`project = azure-windows-automation` and `ephemeral = true`.

### Files and directories

Lowercase with hyphens (`vm-config`, not `VmConfig`), unless the tooling requires otherwise.

## Auth & security

- **Azure authentication** — local runs use the operator's `az login` session (the `azurerm`
  provider picks it up). CI uses a service principal with a client secret, passed as `ARM_CLIENT_ID`,
  `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`. OIDC (federated credentials) is
  deferred until the project moves to its target version control system.
- **VM credentials** — admin passwords and other secrets come from the environment or a secret
  store; never from tracked files.

## Configuration

All config is environment / a gitignored `.env` (never tracked):

| Setting | Purpose |
|---------|---------|
| | _TBD_ |

## Deployment

_TBD — how a deployment is run, locally and/or from CI._

## Known platform constraints (Azure)

_TBD — Azure-side facts the design works around (quotas, SKU availability, image licensing, etc.)._

## Tech stack (proposal — confirm in an issue)

- **Infrastructure as code:** Terraform with the `azurerm` provider (used by the experiments).
- **Guest scripts:** Windows PowerShell 5.1 (present on every image).

Open decisions: guest configuration default (Custom Script Extension vs. Managed Run Command),
target Windows Server version(s) and VM size(s), region.
