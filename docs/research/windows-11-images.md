# Windows 11 images in the Azure Marketplace

Snapshot of `MicrosoftWindowsDesktop` images in `westeurope`, taken 2026-10-26 with:

```bash
az vm image list-skus -l westeurope -p MicrosoftWindowsDesktop -f windows-11
az rest --method GET --url ".../offers/windows-11/skus/<sku>/versions" --url-parameters api-version=2024-07-01
```

The list changes every month; rerun the commands for the current state.

## How to read an image version

`26200.9711.261011` = **OS build 26200.9711**, image published **2026-10-11** (`yymmdd`).
The first part is the Windows build (`26100` = 24H2, `26200` = 25H2), the second is the update
revision (UBR) and identifies the monthly cumulative update.

## Offer `windows-11` (general availability)

All images are x64, Generation 2, `SecurityType = TrustedLaunchAndConfidentialVmSupported`.

### Versions and builds

| Windows version | OS build | Image versions available (OS build.UBR, publish date) |
|-----------------|----------|--------------------------------------------------------|
| 23H2 | 22631 | 22631.7219 (2026-06-07), 22631.7376 (2026-07-11), 22631.7517 (2026-08-09), 22631.7582 (2026-09-07), 22631.7652 (2026-10-13) |
| 24H2 | 26100 | 26100.8655 (2026-06-07), 26100.8875 (2026-07-11), 26100.9168 (2026-08-09), 26100.9445 (2026-09-08), 26100.9457 (2026-09-13), 26100.9711 (2026-10-11) |
| 25H2 | 26200 | 26200.8655 (2026-06-07), 26200.8875 (2026-07-11), 26200.9168 (2026-08-09), 26200.9445 (2026-09-08), 26200.9457 (2026-09-13), 26200.9711 (2026-10-11) |
| 26H2 | 26300 | 26300.9457 (2026-09-13), 26300.9711 (2026-10-11) |

Every SKU of a given Windows version carries the same set of image versions.

### SKUs (editions)

| SKU suffix | Edition | 23H2 | 24H2 | 25H2 | 26H2 |
|------------|---------|:----:|:----:|:----:|:----:|
| `-ent` | Enterprise | ✓ | ✓ | ✓ | ✓ |
| `-entn` | Enterprise N (without media features) | ✓ | ✓ | ✓ | ✓ |
| `-ent-ltsc` | Enterprise LTSC 2024 | | ✓ | | |
| `-entn-ltsc` | Enterprise N LTSC 2024 | | ✓ | | |
| `-pro` | Pro | | ✓ | ✓ | ✓ |
| `-pron` | Pro N | | ✓ | ✓ | ✓ |
| `-pro-zh-cn` | Pro, Chinese (Simplified) | | ✓ | ✓ | ✓ |
| `-avd` | Enterprise multi-session (Azure Virtual Desktop) | ✓ | ✓ | ✓ | ✓ |

Full SKU name: `win11-<version>-<suffix>`, for example `win11-25h2-ent`. URN:
`MicrosoftWindowsDesktop:windows-11:win11-25h2-ent:26200.9711.261011`.

## Other offers with Windows 11 (not used)

| Offer | Contents |
|-------|----------|
| `windows11preview` | Preview images: 21H2 leftovers, 26H2, Arm64 builds, Cloud PC and M365 variants |
| `windows11preview-arm64` | Arm64 Enterprise/Pro, 22H2 – 26H2 |
| `windows-ent-cpc` | Windows 365 Cloud PC images (`-cpc`, `-cpc-m365`, `-cpc-devready`), 22H2 – 26H2 |
| `office-365` | Multi-session with Microsoft 365 Apps (`-avd-m365`), 22H2 – 26H2 |

## Implications

- **Retention is about five months.** The oldest image versions are from June 2026; a pinned
  version disappears from the Marketplace after a few months. Pinning a Marketplace version works
  for a test campaign, not for long-term reproducibility of a certified build — that needs a
  custom image in an Azure Compute Gallery.
- **LTSC is only available for 24H2.** If the certification targets a long-term-servicing build,
  `win11-24h2-ent-ltsc` (Windows 11 Enterprise LTSC 2024) is the only Marketplace option.
- **23H2 is still offered**, but only Enterprise editions.
