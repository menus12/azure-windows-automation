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

Test VMs run Windows 11 Pro 26H2 from the Marketplace (`win11-26h2-pro`, the version fixed for
the experiments; [research](research/windows-client.md)):
`license_type = "Windows_Client"` and Trusted Launch (`secure_boot_enabled`, `vtpm_enabled`).

## Naming

### Azure resources

_TBD — naming scheme for resource groups, VMs, networks, and other resources._

Experiments use the prefix `awa-poc-` (for example `rg-awa-poc-cfgtest`) and carry the tags
`project = azure-windows-automation` and `ephemeral = true`.

### Files and directories

Lowercase with hyphens (`vm-config`, not `VmConfig`), unless the tooling requires otherwise.

## Auth & security

- **Azure authentication** — Terraform and Azure CLI run as a service principal, passed as
  `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`. The same variables
  are what an Azure DevOps Server pipeline will set later. OIDC (federated credentials) is
  deferred until the project moves to its target version control system.
- **Client secret on the operator VDI** — encrypted with Windows DPAPI and loaded by the
  PowerShell profile, not stored as a plain environment variable
  ([runbook](runbooks/vdi-setup.md)).
- **VM credentials** — admin passwords and other secrets come from the environment or a secret
  store; never from tracked files.
- **Environment details stay local.** The repository is public: subscription, tenant, and client
  IDs, storage account names, and proxy hosts live in local settings (`ARM_*`, `*.tfbackend`),
  not in tracked files.

## Configuration

All environment-specific configuration is local and never tracked:

| Setting | Where | Purpose |
|---------|-------|---------|
| `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` | User environment variables | Service principal and target subscription |
| `ARM_CLIENT_SECRET` | DPAPI file + PowerShell profile | Service principal secret |
| `HTTPS_PROXY`, `HTTP_PROXY`, `NO_PROXY` | User environment variables | Corporate proxy for Azure CLI and Terraform |
| `<environment>.azurerm.tfbackend` in the experiment directory | Git-ignored file | Terraform state storage account, container, and key |

## Deployment

Experiments run from PowerShell on the operator VDI ([runbook](runbooks/vdi-setup.md)):

- **Remote state** in an Azure Storage container through the `azurerm` backend with
  `use_azuread_auth = true`. The backend block is a partial configuration; the storage details and
  the state key come from the `*.tfbackend` file. Only `windows-provisioning` is set up for remote
  state; the next stage moves to Azure DevOps Server pipelines.
- **Outbound access through the corporate proxy only** — Azure CLI and Terraform need
  `HTTPS_PROXY` set explicitly; they don't pick up the Windows proxy settings.

## Known platform constraints (Azure)

- **VM sizes are restricted on the PoC subscription in `westeurope`.** `Standard_B2s` failed on
  regional capacity, and the Dsv5, Dasv5, and Bsv2 sizes report `NotAvailableForSubscription`.
  The v7 generation (for example `Standard_D2s_v7`) is available. Check before choosing a size:
  `az vm list-skus -l <region> --size <size> --query "[].restrictions"`.
- **Dsv6/Dsv7 and newer sizes support only an NVMe disk controller.** Set
  `disk_controller_type = "NVMe"`; the Windows 11 Marketplace images support it.

## Tech stack (proposal — confirm in an issue)

- **Infrastructure as code:** Terraform with the `azurerm` provider (used by the experiments).
- **Guest scripts:** Windows PowerShell 5.1 (present on every image).

Open decisions: guest configuration default (Custom Script Extension vs. Managed Run Command),
target Windows Server version(s) and VM size(s), region.
