# Fedora: migrate tsafe 4.1 from Cargo to tsafe 4.2 through DNF

**Prepared for the signed 4.2.0 release. The DNF channel is not yet published.**
Use the installation steps below only after the
[4.2.0 release](https://github.com/0ryant/tsafe-releases/releases/tag/tsafe-v4.2.0)
announces the signed RPM channel and its full OpenPGP fingerprint. A missing
release, key, repository file or signature is a reason to stop, not to disable
signature verification.

This changes who manages your executables. Keep the same Linux user, profiles,
vault files and path settings. **Do not run `tsafe init` to migrate.** Run vault
commands as your normal user; only package administration needs `sudo`.

## What changes

| | Cargo bundle: `cargo install tsafe --locked` | DNF package: `tsafe` |
|---|---|---|
| Location | Usually `~/.cargo/bin`; a custom Cargo install root is possible | `/usr/bin` |
| Shared binaries | `tsafe`, `tsafe-agent`, `tsafe-mcp` | All three |
| Other companions | `tsafe-nativehost`, `tsafe-tray` | Standalone `tsafe-ui`; no nativehost or tray |
| Next update | Another Cargo build | `sudo dnf upgrade tsafe` |
| Build tools | Rust and applicable development dependencies | Prebuilt binaries; DNF installs runtime dependencies |

The RPM supports the published x86_64/aarch64 builds with glibc 2.39 or newer.
It includes man pages. Libraries such as `tsafe-core` are compiled into the
executables: you do not install a separate `tsafe-core` RPM.

DNF does not update or remove Cargo-managed files. If Cargo's bin directory
leads `PATH`, the old 4.1 command will still win until you resolve the overlap.

## 1. Record the old installation and back up your data

In your usual shell, before changing anything:

```bash
type -a tsafe tsafe-agent tsafe-mcp tsafe-nativehost tsafe-tray
tsafe --version
tsafe build-info
cargo install --list
tsafe status --json
```

Use `--profile NAME` with `status` and later checks for a non-default profile.
Record each profile's `vault.path` and keep the same `TSAFE_PROFILE`,
`TSAFE_VAULT_DIR`, `TSAFE_AGE_IDENTITY`, XDG directory settings and project
contracts. Do not paste vault metadata or environment dumps into an issue.

Pause processes that write to the vault. Close MCP clients and tray processes;
if an agent session is running, revoke that session with `tsafe agent lock`.
Know your master password or have your tested recovery method available.

Create a private backup directory and preserve the existing executables:

```bash
umask 077
tsafe_backup="$HOME/tsafe-backup-4.1-to-4.2-$(date +%Y%m%d-%H%M%S)"
mkdir -m 700 "$tsafe_backup"
mkdir "$tsafe_backup/bin"
cargo install --list > "$tsafe_backup/cargo-install-list.txt"
tsafe status --json > "$tsafe_backup/status-before.json"
for name in tsafe tsafe-agent tsafe-mcp tsafe-nativehost tsafe-tray; do
    executable=$(type -P "$name") || continue
    cp -pL -- "$executable" "$tsafe_backup/bin/$name"
done
```

Copy the encrypted vaults **and their snapshots**, configuration/theme files,
audit logs **and sealed-head sidecars**, and any team age identities into this
private backup. For the normal layout without `TSAFE_VAULT_DIR`:

```bash
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tsafe"
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/tsafe"
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/tsafe"
[[ ! -d "$data_dir" ]] || cp -a -- "$data_dir" "$tsafe_backup/data"
[[ ! -d "$config_dir" ]] || cp -a -- "$config_dir" "$tsafe_backup/config"
[[ ! -d "$state_dir" ]] || cp -a -- "$state_dir" "$tsafe_backup/state"
```

If `TSAFE_VAULT_DIR` is set, copy that actual directory, including its
`snapshots/`. Also preserve its sibling `config.json`, `theme.json`, `state/`
and `age/` where present. Back up a separately configured `TSAFE_THEME_FILE`
and `TSAFE_AGE_IDENTITY` too. Without an identity override, team identity files
normally live under `~/.age/`. Keep private identities and backup metadata
protected. The vault backup does not export your OS keyring or its audit key.

Check that the backup contains the recorded vault paths and recovery material
before proceeding. Keep it until you have completed the verification below.

## 2. Install from the announced signed channel

After publication, download the public key and repository configuration:

```bash
tsafe_repo_tmp=$(mktemp -d)
curl --fail --show-error --silent --proto '=https' \
  https://0ryant.github.io/tsafe-releases/rpm/RPM-GPG-KEY-tsafe \
  -o "$tsafe_repo_tmp/RPM-GPG-KEY-tsafe"
curl --fail --show-error --silent --proto '=https' \
  https://0ryant.github.io/tsafe-releases/rpm/tsafe.repo \
  -o "$tsafe_repo_tmp/tsafe.repo"
mkdir -m 700 "$tsafe_repo_tmp/gnupg"
gpg --homedir "$tsafe_repo_tmp/gnupg" --show-keys --with-fingerprint \
  "$tsafe_repo_tmp/RPM-GPG-KEY-tsafe"
cat "$tsafe_repo_tmp/tsafe.repo"
```

Compare the **entire primary-key fingerprint** with the fingerprint announced
on the release page. Do not trust a short key ID. The repository must use:

```ini
[tsafe]
baseurl=https://0ryant.github.io/tsafe-releases/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://0ryant.github.io/tsafe-releases/rpm/RPM-GPG-KEY-tsafe
sslverify=1
```

Only after those checks, register the verified files and install **4.2.0**:

```bash
sudo rpm --import "$tsafe_repo_tmp/RPM-GPG-KEY-tsafe"
sudo dnf config-manager addrepo --from-repofile="$tsafe_repo_tmp/tsafe.repo"
sudo dnf --refresh install 'tsafe-4.2.0-1'
```

DNF may separately ask to import the metadata-signing key. Check the same full
fingerprint. Keep both package and repository signature verification enabled;
do not use `--nogpgcheck`, an unsigned CI RPM, or a rehearsal key for migration.

## 3. Verify the RPM before removing the Cargo copy

Use explicit paths so an old Cargo binary cannot affect this check:

```bash
rpm -q tsafe
rpm -V tsafe
/usr/bin/tsafe --version
/usr/bin/tsafe build-info
/usr/bin/tsafe status --json
/usr/bin/tsafe biometric status
/usr/bin/tsafe doctor --json
```

Expect version **4.2.0**, build profile **default-core**, and the **same vault
path/profile** recorded earlier. `rpm -V` should print nothing. `status`
reports state without decrypting or modifying the vault; `doctor` can return
1 for a warning or 2 for a critical problem. Read the reported cause before
continuing. An unexpected empty/missing vault usually means a different user,
profile or path setting; do not initialize over the problem.

Confirm decryption using a harmless command that prints no secret values:

```bash
/usr/bin/tsafe exec --minimal --keys YOUR_EXISTING_SAFE_KEY -- /usr/bin/true
```

Replace `YOUR_EXISTING_SAFE_KEY` with an ordinary existing secret permitted for
environment injection. Repeat with `--profile NAME` for other profiles. Use
your usual OS unlock method if enrolled; otherwise the CLI prompts normally.
Keep master passwords out of command arguments and shell history.

In a terminal, run `/usr/bin/tsafe-ui`, unlock the same profile and confirm the
expected entries and theme. On headless WSL, password and agent flows work
without a desktop; OS quick unlock additionally needs a functioning Secret
Service session. A genuine stale-keyring error after a password change has an
explicit recovery command: `/usr/bin/tsafe biometric re-enroll`.

## 4. Move command resolution to DNF and restart clients

For an installation owned by the **`tsafe` bundle crate**, remove only the
three overlapping Cargo binaries after the checks above pass:

```bash
cargo uninstall tsafe --bin tsafe --bin tsafe-agent --bin tsafe-mcp
hash -r
type -a tsafe tsafe-ui tsafe-agent tsafe-mcp
tsafe --version
```

This preserves the bundle's `tsafe-nativehost` and `tsafe-tray`. Cargo supports
[selective binary removal](https://doc.rust-lang.org/cargo/commands/cargo-uninstall.html).
If you used a custom install root, supply the same `--root` to Cargo. If
`cargo install --list` instead shows separate `tsafe-cli`, `tsafe-agent` or
`tsafe-mcp` packages, uninstall only the overlapping packages actually listed.
**Do not run an unqualified `cargo uninstall tsafe` if you need its other two
companions.** Updating the whole Cargo bundle later may restore overlapping
binaries; keep its remaining companions' lifecycle separate from DNF.

All four RPM commands should now resolve to `/usr/bin` (or an equivalent
Fedora `/bin`/`/usr/sbin` symlink). Remove an old shell alias/function if it
still overrides resolution; do not remove the entire Cargo bin directory.

Clear the revoked session locator in this shell, and start the RPM agent if
you use it:

```bash
unset TSAFE_AGENT_SOCK
TSAFE_AGENT_BIN=/usr/bin/tsafe-agent /usr/bin/tsafe agent unlock
# Apply the export line printed by this command to this shell.
/usr/bin/tsafe agent status --json
```

Update any persisted `TSAFE_AGENT_BIN` override as well. Confirm a running
agent reports `agent_build_version: "4.2.0"` and a matching protocol.

In MCP host configurations, change only the executable path to
`/usr/bin/tsafe-mcp` (or `/usr/bin/tsafe` for `tsafe mcp serve`). Preserve the
bound profile, contract, workdir and access restrictions. Restart the host
and validate status, an execution plan and an allowed contract command.
Restart any retained nativehost/tray integrations and check them separately;
they remain Cargo-managed and are not included in the RPM test claim.

## 5. Future upgrades and rollback

After migration, normal updates use:

```bash
sudo dnf upgrade tsafe
```

Restart long-running agent/MCP/TUI processes after upgrading so they use the
new executables. DNF removal does not remove your user-owned vaults.

If validation fails, stop the new clients and agent. Retain the current vault
and audit state, then use the **saved 4.1 executable by its explicit backup
path**, with `TSAFE_AGENT_BIN` pointing to its saved matching agent if needed.
You can remove the RPM with `sudo dnf remove tsafe`; keep your backups. If
reinstalling through Cargo, use your original package/root and pin 4.1.0, for
example `cargo install tsafe --version 4.1.0 --locked`.

Do not restore an older vault over newer writes automatically. If data restore
is needed, first save the newer files separately and restore the matching
vault/config/audit-head set from the backup. A restored pre-rotation vault
requires its old master password; the keyring may need re-enrollment. Never
rewrite or re-anchor an audit chain merely to silence an integrity failure.

## What has been verified before publication

The actual 4.2.0 Linux CI RPM was installed in Fedora 44 WSL x86_64 and passed
113 distinct package/runtime checks. They included reading a vault and Secret
Service credential created by the **published 4.1.0 Linux binary** without
re-enrollment, reading a new 4.2 value with 4.1, agent interoperability, modern
and legacy MCP, TUI editing/themes, and DNF reinstall/remove/reinstall with
all test vaults preserved. Cargo PATH shadowing was also reproduced.

Those tests used isolated synthetic data and an unsigned candidate RPM; they
do not establish production signature trust, a particular custom Cargo build,
ARM64 runtime behavior or every desktop integration. Before enabling this
guide's install instructions, the release maintainer must publish the verified
key/fingerprint and signed packages/metadata, then validate installation from
the public URL. See the [RPM channel README](README.md).
