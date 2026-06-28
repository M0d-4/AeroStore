<p align="center">
  <img src="AltStore/Resources/Icons.xcassets/AeroStoreMark.imageset/AeroStoreMark.png" width="128" height="128" alt="AeroStore" />
</p>

# AeroStore

A community-driven alternative app store for iOS. Sideload, manage, and refresh apps on your device — no jailbreak required.

## Quick Start

### Download the latest IPA

Grab the latest signed or unsigned release from the **[Releases](https://github.com/Leviidev/AeroStore/releases)** tab.

Or trigger an unsigned build yourself via **Actions → Get IPA (unsigned)** → **Run workflow**.

### Sideloading

Install the IPA using any sideloading tool:

- **AltServer** (macOS/Windows) — AltStore's companion tool
- **SideStore** — wirelessly refresh without a computer
- **LiveContainer** — run multiple apps from one install
- **TrollStore** — permanent signing (if你的 device supports it)
- **iLoader** / **Feather** / **Sideloadly** — standard sideloading tools

After installing, go to **Settings → General → VPN & Device Management** and trust your developer certificate.

### Pairing File

On first launch, AeroStore needs a **pairing file** to communicate with your device for installing and refreshing apps.

**Getting a pairing file:**

- **AltServer** — Connect your device to a computer running AltServer; the pairing file is generated automatically
- **MobileDevicePairing** — Use tools like `idevicepair` to generate one
- **iLoader** — Can fetch and import a pairing file directly on-device
- **SideStore** — If you already have SideStore set up, it can export its pairing file

You can also tap **Browse without pairing** to explore available sources — add the pairing file later in **Settings** when you're ready to install or refresh.

## Features

- Browse and install apps from community sources
- Refresh apps wirelessly to keep them signed
- On-device JIT via StikJIT
- Background app refresh
- Custom bundle ID overrides
- Multi-persona account management

## Sources

Add catalogs in **Browse → Add catalog** to discover apps. The default source is included after install.

## Building from Source

Developers: see [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

AGPLv3 — see [LICENSE](LICENSE).
