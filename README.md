# tsafe releases

Compiled releases of **tsafe**, a local-first secrets runtime for developers:
credentials live in an encrypted local vault and are injected into the
environment of the command you run (`tsafe exec`), so they never sit in shell
history, `.env` files or a pasted token.

The source repository is private. This repository publishes the compiled
artifacts, package repositories and installation documentation. The crates themselves are
public on crates.io.

## Install

From source, any platform with a Rust toolchain:

```
cargo install tsafe-cli --version 4.2.0 --locked
```

**apt (Debian/Ubuntu, amd64 + arm64)** — signed repository:

```bash
sudo install -m0755 -d /etc/apt/keyrings
curl -fsSL https://0ryant.github.io/tsafe-releases/apt/tsafe-archive-keyring.gpg | sudo tee /etc/apt/keyrings/tsafe.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/tsafe.gpg] https://0ryant.github.io/tsafe-releases/apt stable main" | sudo tee /etc/apt/sources.list.d/tsafe.list >/dev/null
sudo apt update && sudo apt install tsafe
```

**Fedora / DNF (4.2.0)** — the signed RPM channel is available for x86_64 and
aarch64. It is hosted here as a third-party repository, not in Fedora's own
package collection.
See [RPM channel requirements and Cargo migration](rpm/README.md). Existing
Cargo installations are not upgraded by DNF and can take precedence on PATH.
The [step-by-step 4.1 Cargo → 4.2 DNF guide](rpm/MIGRATE-4.1-CARGO-TO-4.2-DNF.md)
covers preserving vaults, verifying signatures, retaining tray/nativehost,
switching command paths and rollback.

Fedora users add our repository once:

```bash
sudo dnf config-manager addrepo --from-repofile=https://0ryant.github.io/tsafe-releases/rpm/tsafe.repo
sudo dnf --refresh install tsafe
```

Check DNF's key-import fingerprint against the release announcement. Future
updates use `sudo dnf upgrade tsafe`. These are the
[DNF5 repository-add commands](https://dnf5.readthedocs.io/en/latest/dnf5_plugins/config-manager.8.html)
used by Fedora 44. Verify the RPM signing-key fingerprint
`4E5971C6925D9EEA1E029F9CF18C6833D9BC9623` before accepting the first key
import. Existing Cargo users should follow the migration guide before removing
their old installation.

Other channels: **Chocolatey** (`choco install tsafe`) and
**Homebrew** (a `0ryant/tsafe` tap, in progress) are being brought up on the same
model.

From a compiled archive: pick the release for the tag you want under
**Releases**, download the archive for your platform, verify it against
`SHA256SUMS.txt` from the same release, and put the binaries on your `PATH`.

## What a release contains

- `tsafe-<version>-default-core-full-<target>.zip` — the `default-core-full`
  stack: `tsafe` (CLI), `tsafe-ui` (terminal UI), `tsafe-agent` (session
  agent), `tsafe-mcp` (bound-contract MCP server), plus manpages.
- `SHA256SUMS.txt` — SHA-256 of every asset above.

## What is and is not claimed

Each release page states its own claims. For 4.2.0, the Windows and Linux
archives remain unsigned at the executable level (no Authenticode, notarization
or cosign signature), while APT metadata is signed with the established key and
RPM packages plus DNF metadata are signed with the announced RPM key. The
default-core-full bundle contains `tsafe`, `tsafe-ui`, `tsafe-agent` and
`tsafe-mcp`. Linux x86_64 has native Fedora and Ubuntu installation evidence;
the aarch64 payload has bounded QEMU smoke coverage and remains qualified for
native-install verification.

## Verify a download

```
sha256sum -c SHA256SUMS.txt
```

## Issues

Use this repository's issue tracker for install and packaging problems.

## License

AGPL-3.0-or-later. See `LICENSE`.
