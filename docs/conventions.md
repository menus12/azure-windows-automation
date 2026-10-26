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

## Naming

### Azure resources

_TBD — naming scheme for resource groups, VMs, networks, and other resources._

### Files and directories

Lowercase with hyphens (`vm-config`, not `VmConfig`), unless the tooling requires otherwise.

## Auth & security

- **Azure authentication** — _TBD_ (interactive login, service principal, or managed identity).
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

_TBD._

Open decisions: infrastructure-as-code tool, guest configuration mechanism, Azure authentication
method for local runs and CI, target Windows Server version(s) and VM size(s), region.
