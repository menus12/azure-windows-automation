# Research: deploy-time configuration of Windows VMs in Azure

**Question.** cloud-init configures Linux VMs in Azure at deploy time. Does an equivalent work for
Windows VMs, and which mechanism should this project use?

**Short answer.** There is no cloud-init for Windows in Azure. Custom data and user data are
delivered to a Windows VM but never executed. Configuration at deploy time works through the VM
Agent: the **Custom Script Extension** or **Managed Run Command**. Both worked on the first try.

## What the documentation says

- cloud-init in Azure is documented for Linux only; Azure supports two provisioning agents,
  cloud-init and the Azure Linux Agent ([cloud-init support][cloud-init]).
- On Windows, custom data "is placed in *%SystemDrive%\AzureData\CustomData.bin* as a binary
  file, but it isn't processed. To process this file, build a custom image and write code that
  reads *CustomData.bin*" ([custom data][custom-data]).
- User data is retrievable from IMDS, persists for the lifetime of the VM, and can be updated
  without a reboot; it is not executed either ([user data][user-data]).
- cloudbase-init (a third-party cloud-init for Windows) requires a custom image and is not a
  Microsoft-supported path.
- The Custom Script Extension downloads and runs scripts as `LocalSystem`, once per configuration,
  within 90 minutes, and must not restart the VM ([Custom Script Extension][cse]).
- Managed Run Command is a separate resource type intended, among others, for scripts that "need
  to run as part of VM deployment"; up to 25 per VM, custom timeout, full output to a blob
  ([Run Command][run-command]).

## Experiment

Terraform configuration and scripts: [experiments/windows-provisioning](../../experiments/windows-provisioning/).

- **Date:** 2026-10-26
- **Image:** Windows Server 2022 Datacenter (`2022-datacenter-smalldisk-g2`, latest)
- **Size / region:** `Standard_B2s`, `westeurope`
- **Tooling:** Terraform 1.17.0, `azurerm` provider 4.x; VM Agent 2.7.41491.1243

### Results

| Test | Mechanism | Result |
|------|-----------|--------|
| A | `custom_data` | `C:\AzureData\CustomData.bin` present, **plain text** (not Base64), 1165 bytes. **Not executed**: no autorun marker |
| B | `user_data` | Returned by IMDS (`/metadata/instance/compute/userData`, Base64). **Not executed**: no autorun marker |
| C | Custom Script Extension running the custom data payload | **Succeeded.** 7-Zip 26.05 installed, `7z.exe` runs. Executed as `NT AUTHORITY\SYSTEM` |
| D | Managed Run Command | **Succeeded.** PowerShell 7.6.9 installed, `pwsh.exe` runs. Exit code and stdout visible in the Terraform resource's `instance_view` |

### Timing

| Step | Duration |
|------|----------|
| VM resource (`azurerm_windows_virtual_machine`) | 1 min 41 s |
| Custom Script Extension resource | 2 min 46 s (the script itself: ~4 s) |
| Managed Run Command resource | 56 s (the script itself: ~28 s, mostly the 112 MB download) |
| Whole `terraform apply` | ~6.5 min |

Most of the extension's time is the VM Agent installing the extension handler, not the script.

### Observations

- **Custom data + Custom Script Extension is a workable "cloud-init for Windows".** The script
  lives in the Terraform configuration, travels as custom data, and a one-line extension command
  executes it. No storage account or public URL is needed to host the script.
- `CustomData.bin` contains the decoded payload as is, so it can be copied to a `.ps1` file and run.
- Passing the wrapper as `powershell -EncodedCommand` (UTF-16LE Base64, via Terraform's
  `textencodebase64`) avoids all quoting problems in `commandToExecute`. Side effect: the
  extension status contains a `#< CLIXML` progress record on stderr, which is noise, not an error.
- Terraform waits for both the extension and the run command to finish, so a successful
  `terraform apply` means the configuration has run.
- Outbound downloads worked through a Standard public IP with no inbound rules.

## Open questions

- Does `terraform apply` fail when the script fails (non-zero exit / thrown error)? Needed for CI.
- Behavior with scripts that need a reboot (Windows features, some installers).
- Run Command vs. Custom Script Extension as the default: Run Command allows several ordered
  scripts and full output; the extension is the older, more widely documented path.

[cloud-init]: https://learn.microsoft.com/azure/virtual-machines/linux/using-cloud-init
[custom-data]: https://learn.microsoft.com/azure/virtual-machines/custom-data
[user-data]: https://learn.microsoft.com/azure/virtual-machines/user-data
[cse]: https://learn.microsoft.com/azure/virtual-machines/extensions/custom-script-windows
[run-command]: https://learn.microsoft.com/azure/virtual-machines/run-command-overview
