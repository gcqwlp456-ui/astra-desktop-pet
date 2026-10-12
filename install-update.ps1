$ErrorActionPreference = 'Stop'
$petHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
$petsDirectory = [IO.Path]::GetFullPath((Join-Path $petHome 'pets'))
$targetDirectory = [IO.Path]::GetFullPath((Join-Path $petsDirectory 'astra-white-dragon'))
if (-not $targetDirectory.StartsWith($petsDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid destination.' }
$sourceDirectory = Join-Path $PSScriptRoot 'final'
$sourceImage = Join-Path $sourceDirectory 'spritesheet-clarity-v2.png'
$expectedHash = '8a0259cdc3363034ec92cad73616b7682a112e9e5ec8d70f99d6243a6f455c5a'
if ((Get-FileHash -LiteralPath $sourceImage -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) { throw 'Source checksum mismatch.' }
New-Item -ItemType Directory -Path $targetDirectory -Force | Out-Null
$manifestPath = Join-Path $targetDirectory 'pet.json'
$backupDirectory = Join-Path $targetDirectory 'backup-before-clarity-v2'
if ((Test-Path -LiteralPath $manifestPath) -and -not (Test-Path -LiteralPath $backupDirectory)) {
    $oldPet = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $oldImage = [IO.Path]::GetFullPath((Join-Path $targetDirectory $oldPet.spritesheetPath))
    if (-not $oldImage.StartsWith($targetDirectory + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid old image path.' }
    if (-not (Test-Path -LiteralPath $oldImage)) { throw 'Previous sprite is missing; update stopped.' }
    New-Item -ItemType Directory -Path $backupDirectory | Out-Null
    Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $backupDirectory 'pet.json')
    Copy-Item -LiteralPath $oldImage -Destination (Join-Path $backupDirectory ([IO.Path]::GetFileName($oldImage)))
}
$targetImage = Join-Path $targetDirectory 'spritesheet-clarity-v2.png'
Copy-Item -LiteralPath $sourceImage -Destination $targetImage -Force
if ((Get-FileHash -LiteralPath $targetImage -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) { throw 'Installed sprite checksum mismatch.' }
Copy-Item -LiteralPath (Join-Path $sourceDirectory 'pet.json') -Destination $manifestPath -Force
Write-Output "Updated Astra: $targetDirectory"
Write-Output "Previous version preserved: $backupDirectory"
