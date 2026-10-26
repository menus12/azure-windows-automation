# Contributing

## Getting started

1. Read this file
2. Read [docs/conventions.md](docs/conventions.md) for the architecture and technical detail
3. Check open issues before opening a new one

## Language

All documentation, code comments, commit messages, issues, and pull requests are written in
**English**.

## Issue-first workflow

Every change starts with an issue. Check existing issues before creating a new one. Architectural
decisions are discussed in issues and recorded in [docs/conventions.md](docs/conventions.md)
rather than diverging in a PR.

## Branching

Branch from `main` using the issue number:

```
feature/<N>-<short-description>
fix/<N>-<short-description>
docs/<N>-<short-description>
```

## PR process

1. Branch from `main`
2. Implement the change
3. Update docs when behavior or architecture changes
4. Open a PR with a short summary and `Closes #N`

## What not to do

- Don't push directly to `main` — always open a PR
- Don't open a PR without a tracking issue
- **Don't commit secrets.** Azure credentials, service principal secrets, VM admin passwords, and
  any other sensitive values come from the environment (or a local `.env` that is gitignored). No
  credentials in tracked files, examples, tests, or fixtures.
