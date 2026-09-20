[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$OutputDirectory,
    [switch]$KeepPackage
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Assert-ReleaseGate {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Get-XmlElementText {
    param(
        [System.Xml.XmlDocument]$Document,
        [string]$Name
    )

    $element = $Document.SelectSingleNode("//*[local-name()='metadata']/*[local-name()='$Name']")
    if ($null -eq $element) {
        return $null
    }

    return $element.InnerText.Trim()
}

function Test-PngFile {
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -lt 33) {
        return $false
    }

    $signature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
    for ($index = 0; $index -lt $signature.Length; $index++) {
        if ($bytes[$index] -ne $signature[$index]) {
            return $false
        }
    }

    $offset = 8
    $hasHeader = $false
    $hasImageData = $false
    $hasEnd = $false

    while ($offset -lt $bytes.Length) {
        if (($bytes.Length - $offset) -lt 12) {
            return $false
        }

        $chunkLength = (
            ([uint32]$bytes[$offset] -shl 24) -bor
            ([uint32]$bytes[$offset + 1] -shl 16) -bor
            ([uint32]$bytes[$offset + 2] -shl 8) -bor
            [uint32]$bytes[$offset + 3]
        )
        $offset += 4

        $chunkType = [System.Text.Encoding]::ASCII.GetString($bytes, $offset, 4)
        $offset += 4

        $remaining = [uint64]$bytes.Length - [uint64]$offset
        if ($remaining -lt ([uint64]$chunkLength + 4)) {
            return $false
        }

        if ($chunkType -eq 'IHDR') {
            if ($hasHeader -or $chunkLength -ne 13) {
                return $false
            }
            $hasHeader = $true
        }
        elseif ($chunkType -eq 'IDAT' -and $chunkLength -gt 0) {
            $hasImageData = $true
        }
        elseif ($chunkType -eq 'IEND') {
            if ($chunkLength -ne 0) {
                return $false
            }
            $hasEnd = $true
            $offset += 4
            break
        }

        $offset += [int64]$chunkLength + 4
    }

    return $hasHeader -and $hasImageData -and $hasEnd -and $offset -eq $bytes.Length
}

function Read-ZipEntryText {
    param($Entry)

    $stream = $Entry.Open()
    try {
        $reader = [System.IO.StreamReader]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            $true
        )
        try {
            return $reader.ReadToEnd()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path

$packageDirectory = Join-Path $RepoRoot 'chocolatey'
$nuspecPath = Join-Path $packageDirectory 'tsafe.nuspec'
$iconPath = Join-Path $packageDirectory 'tsafe.png'

Assert-ReleaseGate (Test-Path -LiteralPath $nuspecPath -PathType Leaf) "Missing Chocolatey nuspec: $nuspecPath"
Assert-ReleaseGate (Test-Path -LiteralPath $iconPath -PathType Leaf) "Missing Chocolatey icon: $iconPath"

$sourceNuspec = [System.Xml.XmlDocument]::new()
$sourceNuspec.PreserveWhitespace = $true
$sourceNuspec.Load($nuspecPath)
$sourceIconUrl = Get-XmlElementText -Document $sourceNuspec -Name 'iconUrl'
Assert-ReleaseGate (-not [string]::IsNullOrWhiteSpace($sourceIconUrl)) 'Chocolatey nuspec metadata must contain a non-empty iconUrl.'
Write-Output "[PASS] source nuspec contains iconUrl: $sourceIconUrl"

Assert-ReleaseGate (Test-PngFile -Path $iconPath) "Chocolatey icon is not a non-empty PNG: $iconPath"
Write-Output "[PASS] source icon is a non-empty PNG: $iconPath"

$choco = Get-Command choco -ErrorAction SilentlyContinue
Assert-ReleaseGate ($null -ne $choco) 'Chocolatey CLI (choco) is required to run the package gate.'

$temporaryOutput = $false
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("tsafe-chocolatey-gate-{0}" -f ([guid]::NewGuid().ToString('N')))
    $temporaryOutput = $true
}
else {
    $OutputDirectory = [System.IO.Path]::GetFullPath($OutputDirectory)
    if (Test-Path -LiteralPath $OutputDirectory) {
        $existingPackages = @(Get-ChildItem -LiteralPath $OutputDirectory -Filter '*.nupkg' -File)
        Assert-ReleaseGate ($existingPackages.Count -eq 0) "Output directory already contains .nupkg files: $OutputDirectory"
    }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$archive = $null
try {
    Write-Output "[RUN ] choco pack $nuspecPath"
    $packOutput = & $choco.Source pack $nuspecPath --outputdirectory $OutputDirectory --no-progress 2>&1
    $packExitCode = $LASTEXITCODE
    $packOutput | ForEach-Object { Write-Output $_ }
    Assert-ReleaseGate ($packExitCode -eq 0) "choco pack failed with exit code $packExitCode."

    $packages = @(Get-ChildItem -LiteralPath $OutputDirectory -Filter '*.nupkg' -File)
    Assert-ReleaseGate ($packages.Count -eq 1) "Expected exactly one .nupkg in $OutputDirectory; found $($packages.Count)."
    $packagePath = $packages[0].FullName
    Write-Output "[PASS] choco pack produced: $packagePath"

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($packagePath)
    $entryNames = @($archive.Entries | ForEach-Object { $_.FullName.Replace('\', '/') })
    Assert-ReleaseGate ($entryNames -contains 'tools/tsafe.png') 'Packed .nupkg is missing tools/tsafe.png.'
    Write-Output '[PASS] packed .nupkg contains tools/tsafe.png'

    $packagedNuspecEntry = @($archive.Entries | Where-Object { $_.FullName -match '(?i)\.nuspec$' })
    Assert-ReleaseGate ($packagedNuspecEntry.Count -eq 1) "Expected exactly one packaged nuspec; found $($packagedNuspecEntry.Count)."
    $packagedNuspecText = Read-ZipEntryText -Entry $packagedNuspecEntry[0]
    $packagedNuspec = [System.Xml.XmlDocument]::new()
    $packagedNuspec.LoadXml($packagedNuspecText)
    $packagedIconUrl = Get-XmlElementText -Document $packagedNuspec -Name 'iconUrl'
    Assert-ReleaseGate (-not [string]::IsNullOrWhiteSpace($packagedIconUrl)) 'Packaged nuspec metadata must contain a non-empty iconUrl.'
    Write-Output "[PASS] packaged nuspec contains iconUrl: $packagedIconUrl"

    Write-Output "Chocolatey release gate passed for $packagePath"
}
finally {
    if ($null -ne $archive) {
        $archive.Dispose()
    }
    if ($temporaryOutput -and -not $KeepPackage -and (Test-Path -LiteralPath $OutputDirectory)) {
        Remove-Item -LiteralPath $OutputDirectory -Recurse -Force
    }
}
