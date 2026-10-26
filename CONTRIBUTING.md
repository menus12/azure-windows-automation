# Contributing

This document describes how to work in this repository. It is a draft and will be expanded as the project grows.

## Language

All documentation, code comments, commit messages, and pull request descriptions are written in **English**.

## Workflow

1. Create a branch from `main` for each piece of work.
2. Make focused changes; one logical change per pull request.
3. Update the documentation in the same change when behavior, structure, or conventions change.
4. Open a pull request and get it reviewed before merging.

## Branches

_TBD: branch naming scheme._

## Commits

- Write the subject line in the imperative mood ("Add VM module", not "Added VM module").
- Keep the subject line short; explain the *why* in the body when it is not obvious.

## Pull requests

- Describe what changed and why.
- Link the related issue, if there is one.
- Make sure checks pass before requesting review.

## Documentation

The repository follows the committed engineering documentation pattern:

| Document | Purpose |
| --- | --- |
| `README.md` | What the project is and how to get started |
| `CONTRIBUTING.md` | How to work in the repository |
| `docs/conventions.md` | Engineering conventions and rules |

If a change makes any of these documents inaccurate, update them in the same pull request.

## Secrets

Never commit credentials, subscription keys, passwords, or other secrets. _TBD: how secrets are supplied to local runs and CI._
