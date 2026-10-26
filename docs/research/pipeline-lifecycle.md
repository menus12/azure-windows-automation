# Research: test VM lifecycle in a pipeline

**Status: design notes, not tested yet.**

## Target flow

1. `terraform apply` — create the test VM (Windows 11).
2. Deploy-time PowerShell installs the environment, pulls the software under test from Azure
   DevOps, and runs the tests.
3. Collect the results.
4. `terraform destroy` — **always**, whether the tests passed or failed. The VMs are expected to be
   resource-intensive; a VM left running after a broken pipeline must not go unnoticed.

Because the VM is always destroyed, retrying a failed configuration in place is out of scope. The
"scripts must fail loudly" rule from [script-failure.md](script-failure.md) still applies: without
a non-zero exit, the pipeline would run tests on a VM that isn't configured.

## Guaranteed cleanup

Observed in the experiments: `terraform destroy` works after failed scripts (failed extensions and
run commands are deleted with their VM), but `destroy` itself once failed on a transient network
error. One `destroy` step is not enough. Layers:

1. **`destroy` step with `condition: always()`** in Azure Pipelines, with retries for transient
   errors.
2. **Remote state in Azure Storage.** If the agent dies, local state is lost and `destroy` no longer
   knows what to delete.
3. **Janitor by tags.** Every resource group carries `ephemeral = true` and an `expires_at`; a
   scheduled pipeline deletes everything past its expiry. Covers runs that never reached `destroy`.
4. **Budget alert** on the subscription or resource group as the last line.

## Connecting the VM to Azure DevOps

Three options, to be compared and tested:

| Option | How | Pros | Cons |
|--------|-----|------|------|
| **A. Ephemeral self-hosted agent on the test VM** | Provisioning installs the Azure Pipelines agent and registers it in a pool; the next job runs on the VM; the agent is removed before `destroy` | Native tasks for artifacts and test results. Registration with a service principal (agent 3.227.1+), no PAT | Agent registration and cleanup to manage |
| **B. No agent on the VM** | The pipeline runs on a regular agent and starts the test script via Run Command; the VM pulls packages from Azure Artifacts (e.g. with a managed identity added to the organization) and uploads results to a blob | Nothing extra on the VM | Results delivery has to be built |
| **C. Managed DevOps Pools** | Azure DevOps creates a VM from a Compute Gallery image per job and deletes it | Could replace Terraform for the test VMs | Windows 11 support not confirmed in the docs (only server images are listed); different architecture |

Secrets (tokens, keys) must not travel in custom data, which is not encrypted. Use the Custom
Script Extension's `protected_settings` (encrypted), a managed identity on the VM, or Key Vault.

Open question: a test Azure DevOps project where an agent pool can be created.

## Sources

- [Register an agent using a service principal](https://learn.microsoft.com/azure/devops/pipelines/agents/service-principal-agent-registration)
- [Agent authentication options](https://learn.microsoft.com/azure/devops/pipelines/agents/agent-authentication-options)
- [Managed DevOps Pools: configure images](https://learn.microsoft.com/azure/devops/managed-devops-pools/configure-images)
