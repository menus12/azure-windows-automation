# Proposal: on-prem test agent capacity with Azure Arc and Azure Local

**Status:** draft for discussion · **Date:** 2026-10-26 · **Related:** the Azure burst PoC in this repository

## Summary

The vSphere cluster that hosts the Azure DevOps Server test agents runs out of capacity under peak
load. A Proxmox cluster built from non-server PCs is being considered as a quick extension. This
document proposes a different path in three horizons that share one image format and one way of
running tests:

| Horizon | What | Replaces |
|---------|------|----------|
| **0 — Cloud burst** | Ephemeral Windows 11 test VMs in Azure for peak load (the PoC in this repository) | Over-provisioning on-prem for peaks |
| **1 — Interim on-prem extension** | Standalone Hyper-V hosts managed through **Azure Arc-enabled servers**, ephemeral agent VMs | The Proxmox cluster idea |
| **2 — Target private cloud** | **Azure Local**: VMs created through Azure Resource Manager on own hardware | The vSphere cluster |

All three run Hyper-V-based VMs from VHD/VHDX images, so a pinned Windows 11 test image built
once works on every platform. A Proxmox cluster (KVM, qcow2) would sit outside this path.

## 1. Problem

- About 150 VMs on vSphere act as Azure DevOps Server agents for resource-intensive software tests.
- When many tests run at the same time, the cluster runs out of resources.
- vSphere is to be decommissioned because of VMware licensing cost.
- The interim idea is a new Proxmox cluster from non-server PCs to add more agents.

## 2. Why not Proxmox

- **A third management platform.** vSphere, Azure, and Proxmox would each need their own
  tooling, monitoring, patching, access control, and skills.
- **A dead end.** It doesn't lead to the vSphere replacement; it would have to be migrated or
  decommissioned again once the target platform exists.
- **Not the image format of the target platforms.** Test images for Proxmox (KVM/qcow2) are not
  the images used in Azure or on Azure Local (Hyper-V/VHDX).
- **Cluster on desktop hardware.** Shared or replicated storage and quorum on non-server PCs,
  without redundant power, ECC memory, or server-grade NICs, is fragile. Failures there stop tests.

## 3. The root cause: permanent agents

The capacity problem is made worse by the agent model, not only by the platform. 150 permanently
running agent VMs hold their CPU and memory whether or not a test is running, while the demand
comes in peaks.

On any platform the better model is **one ephemeral VM per test run**:

1. Create a VM from a pinned, versioned test image.
2. Configure it, run the tests, collect the results.
3. Delete the VM — always, whether the tests passed or failed.

This frees capacity between runs, gives every run a clean, reproducible OS, and is exactly what
the Azure PoC validates (see [Research](#research-in-this-repository)). The horizons below apply
the same model on-prem.

## 4. Horizon 1 — standalone Hyper-V hosts with Azure Arc-enabled servers

**What it is.** The machines that would have gone into the Proxmox cluster become independent
Hyper-V hosts (no cluster, no shared storage). Each host is connected to Azure with the Azure
Connected Machine agent and appears in Azure as an Arc-enabled server.

**What Azure provides for the hosts:**

- Inventory, tags, and access control through Azure RBAC.
- Run Command and extensions to execute scripts on the hosts from Azure.
- Azure Update Manager, Azure Policy / Machine Configuration, Azure Monitor.

**How test VMs are created.** A script on the host — started by a pipeline through Run Command, or
by a self-hosted agent on the host — creates a Hyper-V VM from the golden VHDX (as a differencing
disk, so creation takes seconds and the base image stays untouched), runs the tests, and deletes
the VM.

**Limitations to be aware of:**

- Arc-enabled servers manage **the host**, not the VMs on it. Test VMs are not Azure resources;
  their lifecycle is our own scripting, not Azure Resource Manager. Creating VMs through Azure
  Resource Manager on-prem requires Azure Local (horizon 2) or VMware/SCVMM with Arc resource
  bridge — standalone Hyper-V is not supported.
- Run Command on Arc-enabled servers is in **preview** and not available in the Azure portal.
- The core Arc control plane (inventory, management) is free; some services cost extra per server
  unless covered by Windows Server Software Assurance or Defender for Servers Plan 2 (see
  pricing).
- Arc supports Windows 10/11 as the host OS only for server-like use; Windows Server is the
  intended host OS.

**Why this is better than Proxmox:** one management plane (Azure) for hosts, the same image format
and test-run model as Azure and Azure Local, and the same skills and scripts carry over to
horizon 2.

## 5. Horizon 2 — Azure Local as the vSphere replacement

**What it is.** Azure Local (formerly Azure Stack HCI) is Microsoft's hyperconverged
virtualization platform on own hardware, managed from Azure. Through Arc resource bridge and a
custom location it appears in Azure like a private region: VMs, disks, networks, and images are
Azure resources, created through the Azure portal, CLI, ARM/Bicep, or Terraform.

**What it brings:**

- VM self-service through Azure Resource Manager with Azure RBAC.
- Own images from a local share or a storage account — pinned test builds stay available as long
  as we keep them.
- Migration of existing VMware VMs through Azure Migrate, with data staying on-prem.
- Single-node deployments are possible for small sites or labs.

**Limitations and costs to be aware of:**

- **Hardware:** validated hardware from the Azure Local catalog. The non-server PCs from the
  Proxmox idea do not qualify.
- **Licensing:** a host fee per physical core per month, plus guest OS licensing. Windows Server
  Datacenter with Software Assurance can waive the host fee through Azure Hybrid Benefit. Windows 11
  test VMs need their own entitlement.
- **Arc resource bridge:** an appliance VM per instance that has to be upgraded at least every
  6 months. If it is unavailable, running VMs keep working but cannot be created or deleted from
  Azure. Continuous outbound connectivity to Azure is required; private link is not supported.
- **Terraform:** a different resource model from Azure VMs (custom location, logical networks,
  NICs, images, `virtualMachineInstances`), covered by Azure Verified Modules on top of the `azapi`
  provider — less mature than `azurerm` for Azure VMs.
- **Guest configuration:** extensions on Azure Local VMs require guest management (the Arc agent
  inside the VM); the deploy-time configuration pattern validated in Azure has to be re-validated.

## 6. Horizon 0 — Azure as burst capacity

The PoC in this repository validates ephemeral Windows 11 test VMs in Azure, created with
Terraform, configured at deploy time, and always destroyed after the run. It covers load peaks
that exceed on-prem capacity without buying hardware for them. With horizons 1 and 2, the same
image and the same test-run model work on-prem and in Azure.

## 7. Comparison

| Criterion | Proxmox cluster | Hyper-V + Arc-enabled servers | Azure Local | Azure (burst) |
|-----------|-----------------|-------------------------------|-------------|---------------|
| Time to first capacity | Short | Short | Months (hardware, deployment) | Short (PoC under way) |
| Hardware | Existing PCs | Existing PCs or servers | Validated servers | None |
| Management plane | Proxmox (new) | Azure for hosts, scripts for VMs | Azure for hosts and VMs | Azure |
| VMs as Azure resources | No | No | Yes | Yes |
| Image format | qcow2 (KVM) | VHDX (Hyper-V) | VHDX (Hyper-V) | VHD (Hyper-V) |
| Path to vSphere replacement | None | Stepping stone | Is the replacement | Complement |
| Main cost | Hardware, operations | Hardware, Windows Server licences | Per-core fee, hardware, licences | Pay per use |
| Main risk | Fragile cluster, dead end | Own VM lifecycle scripting | Resource bridge operations, hardware cost | Cost control |

## 8. Roadmap

1. **Now:** stop the Proxmox cluster. Pilot horizon 1 on one or two machines: Windows Server with
   Hyper-V, Arc-enabled, ephemeral agent VMs from a VHDX.
2. **In parallel:** the infrastructure team gets hands-on with Azure Local in the Jumpstart
   LocalBox sandbox, which runs entirely inside an Azure VM and needs no hardware.
3. **In parallel:** finish the Azure burst PoC (this repository) and build the pinned Windows 11
   test image in a form usable on all platforms.
4. **Next:** sizing and cost estimate for Azure Local as the vSphere replacement, once the open
   questions below are answered.
5. **Then:** Azure Local pilot and migration of the agent workload from vSphere.

## 9. Open questions

These need answers before horizon 2 can be sized and costed:

- **Current capacity:** number of vSphere hosts, their cores and memory; typical agent VM size;
  number of concurrent test runs at peak.
- **The PCs considered for Proxmox:** CPU, memory, disks, TPM 2.0 — whether they are suitable as
  Hyper-V hosts for horizon 1.
- **Licensing:** whether Windows Server Datacenter with Software Assurance is available (Azure
  Hybrid Benefit for Azure Local), and the Windows 11 entitlement for test VMs on own hardware.
- **Azure DevOps Server:** version, and whether a move to Azure DevOps Services is planned — some
  agent features (service principal registration, Managed DevOps Pools) exist only in Services.
- **Network:** outbound connectivity from the on-prem hosts to Azure endpoints required by Arc.

## Sources

### Azure Arc-enabled servers (horizon 1)

- [Azure Arc overview](https://learn.microsoft.com/en-us/azure/azure-arc/overview)
- [Azure Arc-enabled servers overview](https://learn.microsoft.com/en-us/azure/azure-arc/servers/overview)
- [Prerequisites, including Windows client OS guidance](https://learn.microsoft.com/en-us/azure/azure-arc/servers/prerequisites#client-operating-system-guidance)
- [Network requirements](https://learn.microsoft.com/en-us/azure/azure-arc/servers/network-requirements)
- [Run Command on Arc-enabled servers (preview)](https://learn.microsoft.com/en-us/azure/azure-arc/servers/run-command)
- [VM extensions on Arc-enabled servers](https://learn.microsoft.com/en-us/azure/azure-arc/servers/manage-vm-extensions)
- [Plan an at-scale deployment](https://learn.microsoft.com/en-us/azure/azure-arc/servers/plan-at-scale-deployment)
- [Azure Update Manager](https://learn.microsoft.com/en-us/azure/update-manager/overview)
- [Azure Arc pricing](https://azure.microsoft.com/en-us/pricing/details/azure-arc/core-control-plane/)
- Sandbox: [Jumpstart ArcBox for IT Pros](https://jumpstart.azure.com/azure_jumpstart_arcbox/ITPro)

### Azure Local (horizon 2)

- [What is Azure Local](https://learn.microsoft.com/en-us/azure/azure-local/overview)
- [System requirements](https://learn.microsoft.com/en-us/azure/azure-local/concepts/system-requirements-23h2)
- [Validated hardware catalog](https://aka.ms/AzureLocalCatalog)
- [Single-node deployments](https://learn.microsoft.com/en-us/azure/azure-local/concepts/single-server-clusters)
- [Azure Local VM management](https://learn.microsoft.com/en-us/azure/azure-local/manage/azure-arc-vm-management-overview)
- [VM images from a local share](https://learn.microsoft.com/en-us/azure/azure-local/manage/virtual-machine-image-local-share)
- [Azure Arc resource bridge: supported platforms, maintenance, versions](https://learn.microsoft.com/en-us/azure/azure-arc/resource-bridge/overview)
- [Migrate VMware VMs to Azure Local with Azure Migrate](https://learn.microsoft.com/en-us/azure/azure-local/migrate/migration-azure-migrate-vmware-overview)
- [Azure Local pricing](https://azure.microsoft.com/en-us/pricing/details/azure-local/)
- [Terraform: Azure Verified Modules, including Azure Local](https://azure.github.io/Azure-Verified-Modules/indexes/terraform/tf-resource-modules/print.html)
- Sandbox: [Jumpstart LocalBox](https://jumpstart.azure.com/azure_jumpstart_localbox)

### Agents and context

- [Self-hosted Windows agents (Azure DevOps Server 2022)](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/windows-agent?view=azure-devops-2022)
- [Retirement of Azure Arc-enabled SCVMM](https://learn.microsoft.com/en-us/azure/azure-arc/system-center-virtual-machine-manager/transition-guidance)
  — why SCVMM is not an option for new deployments

### Research in this repository

- [Deploy-time configuration of Windows VMs](../research/windows-provisioning.md)
- [Deploy-time script failures](../research/script-failure.md)
- [Windows 11 VMs in Azure](../research/windows-client.md)
- [Windows 11 images in the Marketplace](../research/windows-11-images.md)
- [Custom Windows 11 images](../research/custom-images.md)
- [Test VM lifecycle in a pipeline](../research/pipeline-lifecycle.md)
