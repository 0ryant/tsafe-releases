$ErrorActionPreference = 'Stop'

# tsafe 4.2.0, default-core-full stack (tsafe, tsafe-ui, tsafe-agent, tsafe-mcp),
# downloaded from the GitHub Release for tag tsafe-v4.2.0 and verified by SHA-256.
# The binaries are not code-signed; see the release page for what is and is not claimed.

$packageName = 'tsafe'
$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url64       = 'https://github.com/0ryant/tsafe-releases/releases/download/tsafe-v4.2.0/tsafe-4.2.0-default-core-full-x86_64-pc-windows-msvc.zip'
$checksum64  = '9c50dbb751bd2272993d0d08db6fc31d6890e84c2c181927e3a78f7f8a5a6a53'

$packageArgs = @{
  packageName    = $packageName
  unzipLocation  = $toolsDir
  url64bit       = $url64
  checksum64     = $checksum64
  checksumType64 = 'sha256'
}

Install-ChocolateyZipPackage @packageArgs

# The archive unpacks into one versioned folder. Chocolatey shims every .exe under
# tools\ automatically, so tsafe, tsafe-ui, tsafe-agent and tsafe-mcp land on PATH.
# Manpages ship under share\man for reference; nothing else is written outside tools\.
