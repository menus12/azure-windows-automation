# azure-windows-automation

Proof of concept for automating the deployment of Windows-based virtual machines in Microsoft Azure.

> **Status:** early draft. Scope, tooling, and layout will be filled in as the work progresses.

## Goals

- Provision Windows VMs in Azure repeatably, from code.
- Automate post-deployment configuration of the guest OS.
- Keep the whole flow reproducible and documented in this repository.

## Repository layout

```
.
├── README.md            # This file: what the project is and how to get started
├── CONTRIBUTING.md      # How to work in this repository
└── docs/
    └── conventions.md   # Engineering conventions (naming, style, structure)
```

## Getting started

_TBD: prerequisites, authentication to Azure, and the first deployment walkthrough._

## Documentation

This repository follows the **committed engineering documentation** pattern: the knowledge needed to work on the project lives in the repository, next to the code, and is updated in the same change that makes it necessary.

- [`CONTRIBUTING.md`](CONTRIBUTING.md): workflow, branching, commits, and reviews.
- [`docs/conventions.md`](docs/conventions.md): naming, code style, and structural rules.

All documentation in this repository is written in English.
