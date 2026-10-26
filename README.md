# azure-windows-automation

Proof of concept for **automated deployment of Windows-based virtual machines in Microsoft Azure**
— from an empty subscription to a configured, reachable Windows VM, driven entirely from code in
this repository.

> **Status: draft.** The repository is being bootstrapped. Scope, tooling, and layout are open
> decisions and will be filled in as the work progresses (see open issues).

## Goals

- **Repeatable provisioning** — Windows VMs and their supporting Azure resources (resource group,
  network, storage, identity) are created from code, not by hand in the portal.
- **Automated guest configuration** — post-deployment configuration of the Windows guest OS runs
  as part of the same flow.
- **Reproducible and documented** — everything needed to rerun a deployment lives in the
  repository, except secrets.

## Architecture at a glance

_TBD — to be added once the tooling is chosen._

Full technical reference: [docs/conventions.md](docs/conventions.md).

## Repository layout

```
docs/
  conventions.md    technical reference: architecture, conventions, open decisions
  proposals/        proposals for decisions outside this repository
  research/         findings from experiments and documentation reviews
experiments/        self-contained Terraform experiments (one directory each)
CONTRIBUTING.md     how to work in this repository
README.md           this file
```

## Research

- [Deploy-time configuration of Windows VMs](docs/research/windows-provisioning.md) — cloud-init
  does not exist for Windows in Azure; the Custom Script Extension and Managed Run Command work.
- [Deploy-time script failures](docs/research/script-failure.md) — `terraform apply` fails only on a
  non-zero exit; a failed extension or run command blocks a plain retry.
- [Windows 11 VMs in Azure](docs/research/windows-client.md) — Marketplace images work with the
  same mechanisms; licensing via Multitenant Hosting Rights.
- [Windows 11 images in the Marketplace](docs/research/windows-11-images.md) — versions, builds,
  and editions available, with image retention.
- [Custom Windows 11 images](docs/research/custom-images.md) — Compute Gallery path for builds not
  in the Marketplace (not tested yet).
- [Test VM lifecycle in a pipeline](docs/research/pipeline-lifecycle.md) — guaranteed cleanup and
  Azure DevOps connection options (design notes).

## Proposals

- [On-prem test agent capacity with Azure Arc and Azure Local](docs/proposals/on-prem-test-capacity.md)
  — Hyper-V + Arc-enabled servers instead of a Proxmox cluster; Azure Local as the vSphere
  replacement (draft).

## Deploy & use

_TBD — prerequisites, Azure authentication, and a first-deployment walkthrough._

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) — issue-first, a branch per issue, a PR that links it.
Never commit secrets; all credentials come from the environment.
