# tsafe 4.2.0 release notes

Released 2026-09-20 from frozen source
`53663a4a02e943bba6aee73f99541dd1fc77593b` after ADO pipeline 25 / run 1078.

The `default-core-full` bundle contains `tsafe`, `tsafe-ui`, `tsafe-agent`, and
`tsafe-mcp`. It adds modern MCP lifecycle discovery with legacy compatibility,
bounded secret-stdin delivery, Windows canonical-path handling, and ten TUI
palettes with an F2 appearance editor and persistent custom themes.

Linux packages are signed. RPM packages and DNF metadata use fingerprint
`4E5971C6925D9EEA1E029F9CF18C6833D9BC9623`; APT retains the existing
`E7D498123DDA0EB5EAF3288276FF3E62F9AF82C5` trust key for upgrade continuity.
Verify `SHA256SUMS.txt` and its detached signature before installing archives.

Fedora users can add the repository using [the RPM guide](../../rpm/README.md).
Existing Cargo users should follow [the Cargo-to-DNF migration guide](../../rpm/MIGRATE-4.1-CARGO-TO-4.2-DNF.md)
before removing their Cargo installation.

The x86_64 Fedora package has native signed-install and 113-check runtime
evidence. The aarch64 RPM is signed and passes direct QEMU smoke coverage;
native ARM64 Fedora installroot scriptlets remain qualified for a native ARM64
host because the validation host is x86_64 WSL.

Executables are checksum-pinned but are not Authenticode, notarization, or
cosign signed.
