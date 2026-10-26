# Research: Windows 11 VMs in Azure

**Question.** The software under test is certified for Windows 11 and must be tested on it. What
are the options for running Windows 11 VMs in Azure (not as VDI)?

**Short answer.** Windows 11 images are available natively in the Azure Marketplace. Deploying
them is purely a licensing question: production use requires per-user Windows 11 entitlements
(Multitenant Hosting Rights). Technically, Windows 11 from the Marketplace works with the same
Terraform resources and configuration mechanisms as Windows Server.

## Options

| Option | What it is | Licensing | Notes |
|--------|------------|-----------|-------|
| **1. Marketplace image** | `MicrosoftWindowsDesktop:windows-11:win11-<version>-<edition>` | Multitenant Hosting Rights: Microsoft 365 E3/E5/A3/A5/F3/Business Premium, Windows Enterprise E3/E5, Windows VDA E3/E5, Windows Education A3/A5. Deploy with `license_type = "Windows_Client"` | Tested, works. The image version follows Microsoft's monthly updates |
| **2. Dev/Test offer** | Windows 11 Enterprise images visible to Visual Studio / Dev/Test subscription offers (0023P, 0029P, 0059P, 0060P, 0063P, 0064P, 0148P) | Visual Studio subscription per user, dev/test use only | Not available here: the subscription is an Enterprise Agreement (`quotaId: EnterpriseAgreement_2014-09-01`) |
| **3. Custom image** | Own Windows 11 build uploaded as a generalized VHD to an Azure Compute Gallery | Same as option 1 | Needed if a specific, pinned build is required. The built-in administrator is disabled on Windows 11 and has to be enabled for generalized uploads |
| **4. Nested virtualization** | Windows 11 as a Hyper-V guest inside a Windows Server VM | Same as option 1 | Last resort: slower, and Azure extensions/Run Command can't reach the nested VM |

Azure Virtual Desktop and Windows 365 are VDI products and out of scope. The `-avd` SKUs are
Windows 11 Enterprise multi-session for Azure Virtual Desktop and are not used.

## Available SKUs

`az vm image list-skus -l westeurope -p MicrosoftWindowsDesktop -f windows-11` on 2026-10-26
listed, among others: `win11-23h2-ent`, `win11-24h2-ent`/`-pro`, `win11-25h2-ent`/`-pro`,
`win11-26h2-ent`/`-pro`. The experiments use `win11-25h2-ent`.

## Technical requirements

- Generation 2 image and VM size; Trusted Launch (Secure Boot + vTPM). In Terraform:
  `secure_boot_enabled = true`, `vtpm_enabled = true` on `azurerm_windows_virtual_machine`.
- Windows 11 minimum hardware: 2 vCPU, 4 GB RAM, 64 GB disk. `Standard_B2s` meets it.
- Activation happens automatically against Azure KMS.

## Test results

- [Deploy-time configuration](windows-provisioning.md#windows-11): custom data / user data not
  executed; Custom Script Extension and Managed Run Command work.
- [Script failures](script-failure.md#windows-11): same behavior as Windows Server.

## Open questions

- Confirm with licensing that the users running the tests are covered by an eligible license.
- Whether regulatory certification requires a pinned Windows 11 build (option 3) or the current
  Marketplace image of a given version (option 1, with a pinned image version instead of `latest`).

## Sources

- [How to deploy Windows 11 on Azure](https://learn.microsoft.com/azure/virtual-machines/windows/windows-desktop-multitenant-hosting-deployment)
- [Use Windows client images in Azure (dev/test)](https://learn.microsoft.com/azure/virtual-machines/windows/client-images)
- [Trusted launch for Azure VMs](https://learn.microsoft.com/azure/virtual-machines/trusted-launch)
