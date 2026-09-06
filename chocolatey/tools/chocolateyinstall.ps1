$ErrorActionPreference = 'Stop'

# tsafe 4.1.0, default-core-full stack (tsafe, tsafe-ui, tsafe-agent, tsafe-mcp),
# downloaded from the GitHub Release for tag tsafe-v4.1.0 and verified by SHA-256.
# The binaries are not code-signed; see the release page for what is and is not claimed.

$packageName = 'tsafe'
$toolsDir    = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
$url64       = 'https://github.com/0ryant/tsafe-releases/releases/download/tsafe-v4.1.0/tsafe-4.1.0-default-core-full-x86_64-pc-windows-msvc.zip'
$checksum64  = 'a7410d9b372b0366ef9f07443da1e1f3c779abc3bd3d6eec4249a749795ec4d7'

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
