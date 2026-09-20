# Chocolatey release checklist

Run the local gate from the repository root before opening a release PR:

```powershell
pwsh -NoProfile -File .\scripts\validate-chocolatey-package.ps1
```

The gate checks that `chocolatey/tsafe.nuspec` has a non-empty `iconUrl`, that
`chocolatey/tsafe.png` is a valid non-empty PNG, and that `choco pack` carries
both the icon and the `iconUrl` metadata into the generated `.nupkg`.

Before publishing a package:

- [ ] Update the package version and release URLs together.
- [ ] Confirm the archive URL and SHA-256 checksum in `tools/chocolateyinstall.ps1`.
- [ ] Run the local gate and review its generated package contents.
- [ ] Wait for the GitHub Actions Chocolatey release gate to pass on the PR.
- [ ] Publish only the `.nupkg` produced from the reviewed commit.
