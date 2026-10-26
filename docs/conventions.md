# Conventions

Engineering conventions for this repository. This is a draft; sections are filled in as decisions are made. When a convention is agreed on, record it here together with a short rationale.

## General

- English only, in code and documentation.
- Prefer explicit, readable configuration over clever shortcuts.
- Everything needed to reproduce a deployment lives in the repository (except secrets).

## Repository structure

_TBD: where infrastructure code, scripts, and configuration live._

## Naming

### Azure resources

_TBD: naming scheme for resource groups, VMs, networks, and other resources._

### Files and directories

- Use lowercase with hyphens for file and directory names (`vm-config`, not `VmConfig`), unless the tooling requires otherwise.

## Infrastructure as code

_TBD: chosen tooling and its style rules._

## Scripts

_TBD: scripting language(s) and style rules for guest configuration._

## Markdown

- One H1 per document.
- Use relative links between documents in the repository.
