# Changelog

All public distribution changes are recorded here. Each published release also
has a release note and a version comparison in `docs/releases/` and `docs/`.

## 4.2.0 — 2026-09-20

**Theme: safer secret delivery, modern MCP compatibility, signed Linux channels,
and a complete default bundle.**

Published from source `53663a4a02e943bba6aee73f99541dd1fc77593b` after Azure
DevOps pipeline 25 / run 1078 passed on Windows x64, Linux x64, and ARM64.

### User-visible changes

- Added `tsafe exec --secret-stdin[=KEY]`. Selected secrets can be delivered on
  stdin without entering the child environment, argv, or `/proc/<pid>/environ`.
  Bare mode writes framed `NAME=value` entries; single-key mode writes the raw
  value. Ambiguous multiline bare values are refused.
- Secret-stdin delivery is supervised by `--timeout`; a child that does not
  read a large input exits with timeout status 124 and buffers are zeroized.
- Upgraded MCP to rmcp 3.3.0 with 2026-07-28 discovery and compatibility with
  the 2025-11-25 initialization handshake. Bound discovery remains private,
  zero-TTL, and limited to the existing three tools; raw-secret access remains
  refused.
- Fixed Windows bound-command comparison for canonical `\\?\` paths while
  retaining exact allowlist, basename, and workdir boundary checks.
- Added the TUI appearance editor on `F2`, ten palettes, live previews,
  semantic colour overrides, reset/save/cancel, and dedicated `theme.json`
  persistence. Legacy `tui.theme` values remain readable without being written
  back to shared config.
- Fedora source installs of the CLI, agent, and MCP no longer require
  `dbus-devel`; the non-GUI keyring path uses the pure-Rust Secret Service
  backend. The Cargo meta-crate still includes tray dependencies.
- `cargo run -p tsafe-cli` now selects `tsafe` through `default-run`.
- Vault opening has one tested order across interactive, diagnostic, diff, and
  backup-vault paths, including unattended OS unlock for backup writes.

### Distribution and packaging

- Published all 15 publishable crates to crates.io. `tsafe-core` is published
  before its consumers; `tsafe-mobile-ffi` remains intentionally unpublished.
- The top-level `tsafe` crate installs the five Cargo executables: `tsafe`,
  `tsafe-agent`, `tsafe-mcp`, `tsafe-nativehost`, and `tsafe-tray`.
- Published signed RPM and DEB packages for x86_64 and aarch64, signed DNF
  metadata, signed APT metadata, detached checksums, and the default-core-full
  Linux/Windows archives.
- Fedora x86_64 public DNF installation passed `gpgcheck=1`, `repo_gpgcheck=1`,
  `rpm -V`, version, and binary-hash checks. ARM64 has signed direct-QEMU smoke
  evidence; native ARM64 Fedora installroot scriptlets remain qualified only
  for a native ARM64 host.
- Published Chocolatey `tsafe 4.2.0` with the Windows archive checksum-pinned
  to the GitHub release. The package includes `tools/tsafe.png` and a stable
  gallery `iconUrl`.
- Added the Chocolatey release gate that checks source and packaged icon
  metadata, validates the PNG, packs the nupkg, and inspects its contents.

### Compatibility and explicit limits

- No vault-format or agent-wire-format migration is introduced.
- Fedora DNF does not upgrade or remove a Cargo-managed installation; users
  must follow the migration guide and resolve PATH ownership explicitly.
- Executables are checksum-pinned but are not Authenticode, Apple notarization,
  or cosign signed.
- The egress proxy, live cloud/mobile/browser certification, and native ARM64
  Fedora installation evidence remain outside this release claim.

See [the complete 4.1.0 to 4.2.0 comparison](docs/4.1.0-to-4.2.0.md) and
[the published release notes](docs/releases/tsafe-v4.2.0.md).

## 4.1.0

The 4.1.0 public artifacts remain available in the package repositories and
[the 4.1.0 GitHub release](https://github.com/0ryant/tsafe-releases/releases).
