# RPM / DNF channel preparation

Planned for tsafe 4.2.0, x86_64 and aarch64. **Not yet published.** This directory
does not currently provide a repository configuration, production key or package.
The public install command will be added with the verified signed channel.

The intended package is `tsafe`, containing `tsafe`, `tsafe-ui`, `tsafe-agent`
and `tsafe-mcp`, manpages and the license. The current build baseline requires
glibc 2.39 or newer, libgcc, D-Bus libraries and CA certificates. It does not
claim compatibility with EL8/EL9.

## Channel layout and promotion contract

The release host will supply:

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

Before promotion, verify the announced full OpenPGP fingerprint, every RPM's
signature/version/release/architecture and payload, signed repository metadata,
and all referenced checksums. `tsafe.repo` must enable both `gpgcheck=1` and
`repo_gpgcheck=1`. Record checksums after signing; signing changes RPM bytes.
Unsigned draft RPMs and test keys must never be copied into the live channel.

Test the actual candidate on both architectures: clean installation, upgrade,
reinstallation and removal, CLI build identity, bound MCP, agent, terminal UI
and desktop keyring. A prior-version package rehearsal is not candidate proof.
After deployment, verify fresh installations from the public HTTPS URL.

Preserve `/apt`, `/chocolatey`, `.nojekyll`, previous packages and metadata
referenced by cached clients. Record the previous Pages commit for rollback.
Reverting repository metadata does not downgrade already installed clients.
No private source, private key, vault state or signing workspace belongs here.
Git attributes preserve the exact bytes of signed repository files.

## If you installed with Cargo

`cargo install tsafe --locked` normally places five binaries in `~/.cargo/bin`:
`tsafe`, `tsafe-agent`, `tsafe-mcp`, `tsafe-nativehost` and `tsafe-tray`.
The planned RPM places four binaries in `/usr/bin`: the shared CLI/agent/MCP
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

`cargo uninstall tsafe` also removes its nativehost/tray binaries: do not run it
automatically as part of RPM installation. Retain those companions if you use
them. Later RPM upgrades will use `sudo dnf upgrade tsafe`.

If remaining on Cargo, after publication use
`cargo install tsafe --version 4.2.0 --locked`. `--locked` fixes dependency
resolution; `--version` selects the product release. No vault-format migration
is intended in 4.2.0, but same-vault Fedora migration is a required release test.
