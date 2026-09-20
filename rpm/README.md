# RPM / DNF channel

Live for tsafe 4.2.0 on x86_64 and aarch64. This directory contains the signed
repository configuration, production public key, repository metadata and RPMs.
The [4.1 Cargo → 4.2 DNF migration guide](MIGRATE-4.1-CARGO-TO-4.2-DNF.md)
is prepared for that release and covers backup, signed installation, command
resolution, companion restarts, verification and rollback.

## User command

We host a signed RPM repository on this repository's GitHub Pages site; DNF
reads that repository. There is no upload to a central DNF registry.
Fedora 44 users run:

```bash
sudo dnf config-manager addrepo --from-repofile=https://0ryant.github.io/tsafe-releases/rpm/tsafe.repo
sudo dnf --refresh install tsafe
```

Confirm DNF's signing-key fingerprint is
`4E5971C6925D9EEA1E029F9CF18C6833D9BC9623`. Subsequent updates use
`sudo dnf upgrade tsafe`. Existing Cargo users should first follow the migration
guide above. This is our third-party repository, not inclusion in Fedora's own
package collection.

## Package contents

The package is `tsafe`, containing `tsafe`, `tsafe-ui`, `tsafe-agent`
and `tsafe-mcp`, manpages and the license. The current build baseline requires
glibc 2.39 or newer, libgcc and CA certificates. Linux quick unlock uses the
session's Secret Service; the RPM no longer links libdbus. It does not
claim compatibility with EL8/EL9.

## Channel layout and promotion contract

The release host supplies:

```text
rpm/
  RPM-GPG-KEY-tsafe
  tsafe.repo
  stable/
    x86_64/Packages/*.rpm
    x86_64/repodata/repomd.xml
    x86_64/repodata/repomd.xml.asc
    x86_64/repodata/<checksum-named metadata>
    aarch64/Packages/*.rpm
    aarch64/repodata/repomd.xml
    aarch64/repodata/repomd.xml.asc
    aarch64/repodata/<checksum-named metadata>
```

Before installation, verify the announced full OpenPGP fingerprint, every RPM's
signature/version/release/architecture and payload, signed repository metadata,
and all referenced checksums. `tsafe.repo` must enable both `gpgcheck=1` and
`repo_gpgcheck=1`. Record checksums after signing; signing changes RPM bytes.
Unsigned draft RPMs and test keys must never be copied into the live channel.

Test the actual candidate on both architectures: clean installation, upgrade,
reinstallation and removal, CLI build identity, bound MCP, agent, terminal UI
and desktop keyring. A prior-version package rehearsal is not candidate proof.
After deployment, fresh installations from the public HTTPS URL were verified
for x86_64. The aarch64 package is signed and directly smoke-tested under QEMU;
the current x86_64 WSL host cannot complete Fedora's foreign-architecture
installroot scriptlets, so native ARM64 installation remains a qualification.

Preserve `/apt`, `/chocolatey`, `.nojekyll`, previous packages and metadata
referenced by cached clients. Record the previous Pages commit for rollback.
Reverting repository metadata does not downgrade already installed clients.
No private source, private key, vault state or signing workspace belongs here.
Git attributes preserve the exact bytes of signed repository files.

## If you installed with Cargo

`cargo install tsafe --locked` normally places five binaries in `~/.cargo/bin`:
`tsafe`, `tsafe-agent`, `tsafe-mcp`, `tsafe-nativehost` and `tsafe-tray`.
The 4.2 RPM places four binaries in `/usr/bin`: the shared CLI/agent/MCP
plus standalone `tsafe-ui`; it does not provide nativehost or tray.

DNF cannot upgrade a Cargo-managed copy. Before changing installation methods,
record `type -a tsafe tsafe-agent tsafe-mcp`, `tsafe --version`, `tsafe build-info`
and `cargo install --list`. Keep a tested encrypted backup and the same user,
profile and vault-path configuration. Do not initialize a new vault during migration.

After the channel is announced and verified, install the RPM, then check
`/usr/bin/tsafe --version` and `/usr/bin/tsafe build-info` explicitly. Verify
existing-vault and keyring access, then update and restart agent/MCP launch
configuration. If `~/.cargo/bin` comes first in PATH, the old executable can
still win. Use explicit paths or deliberately choose the installation order.

After verifying the RPM, `cargo uninstall tsafe --bin tsafe --bin tsafe-agent
--bin tsafe-mcp` removes only the overlapping Cargo binaries and preserves
nativehost/tray. An unqualified `cargo uninstall tsafe` removes all five: do
not run it automatically. Follow the detailed guide for custom install roots
or separately installed crates. Later RPM upgrades use `sudo dnf upgrade tsafe`.

If remaining on Cargo, use
`cargo install tsafe --version 4.2.0 --locked`. `--locked` fixes dependency
resolution; `--version` selects the product release. No vault-format migration
is intended in 4.2.0. Published-4.1 vault and Secret Service continuity passed
in Fedora 44 x86_64 candidate tests, and the signed public-channel files are now
deployed.
