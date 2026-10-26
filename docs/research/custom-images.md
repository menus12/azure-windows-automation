# Research: custom Windows 11 images

**Status: documentation review, not tested yet.**

**Question.** If certification requires a specific Windows 11 build that the Marketplace doesn't
offer, how do we deploy it with the same tooling (Terraform) and keep deploy-time scripts working?

**Short answer.** Build a generalized image, publish it as a version in an Azure Compute Gallery,
and point `azurerm_windows_virtual_machine` at it with `source_image_id`. Everything else stays the
same — provided the image contains the **Azure VM Agent**, which the Custom Script Extension and
Run Command depend on.

## Check the Marketplace first

The Marketplace keeps several monthly image versions per SKU (about five months, see
[windows-11-images.md](windows-11-images.md)). If the required build is among them, pin it instead
of `latest`:

```hcl
source_image_reference {
  publisher = "MicrosoftWindowsDesktop"
  offer     = "windows-11"
  sku       = "win11-25h2-ent"
  version   = "26200.9711.261011"
}
```

This covers a test campaign, not long-term reproducibility: the version disappears after a few
months.

## Building the image

| Starting point | Tool | When |
|----------------|------|------|
| Marketplace image + own changes (updates, software, settings) | Packer (`azure-arm` builder) or Azure Image Builder | The Marketplace base is acceptable; the goal is to freeze a state |
| ISO of the required build | Hyper-V: install from ISO → `sysprep /generalize /oobe /mode:vm` → VHD | The build is not in the Marketplace. Neither Packer on Azure nor Image Builder can start from an ISO |

Requirements for an uploaded image (Microsoft's "Prepare a Windows VHD to upload to Azure"
checklist), most relevant here:

- **Azure VM Agent installed.** Without it there are no extensions and no Run Command. Marketplace
  images have it; an image built from an ISO does not.
- Generation 2, fixed-size VHD, generalized with sysprep, RDP enabled.
- On Windows 11 the built-in administrator is disabled by default and has to be enabled for
  generalized uploads (`net user <name> /active:yes`).

## Publishing: Azure Compute Gallery

| Terraform resource | Purpose |
|--------------------|---------|
| `azurerm_shared_image_gallery` | The gallery |
| `azurerm_shared_image` | Image definition: `os_type = "Windows"`, generalized, `hyper_v_generation = "V2"`, Trusted Launch supported |
| `azurerm_shared_image_version` | A pinned version (e.g. `26200.1234.0`) built from an uploaded VHD or a managed image |

## Deploying from the gallery

Replace `source_image_reference` with:

```hcl
source_image_id = azurerm_shared_image_version.this.id
```

Custom data, extensions, Run Command, `license_type = "Windows_Client"`, and Trusted Launch work
as with Marketplace images.

## Proposed experiment

Capture a Windows 11 VM created from the Marketplace into a gallery, deploy a new VM from the
gallery version, and rerun the provisioning test. This validates gallery → Terraform →
provisioning without the ISO step, which can be added once it's known whether a non-Marketplace
build is needed.

## Sources

- [Prepare a Windows VHD to upload to Azure](https://learn.microsoft.com/azure/virtual-machines/windows/prepare-for-upload-vhd-image)
- [Upload a generalized VHD](https://learn.microsoft.com/azure/virtual-machines/windows/upload-generalized-managed)
- [How to deploy Windows 11 on Azure](https://learn.microsoft.com/azure/virtual-machines/windows/windows-desktop-multitenant-hosting-deployment)
