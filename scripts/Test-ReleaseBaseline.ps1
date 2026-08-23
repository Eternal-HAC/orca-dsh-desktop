[CmdletBinding()]
param(
    [string]$ArtifactRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) "dist\DeepSeekHarness")
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-PowerShellSyntax {
    param([string]$Path)
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors) | Out-Null
    if ($errors.Count -gt 0) {
        throw "PowerShell syntax failed for $Path`n$($errors.Message -join [Environment]::NewLine)"
    }
}

foreach ($script in @(
    (Join-Path $repoRoot "build.ps1"),
    (Join-Path $repoRoot "package-release.ps1"),
    (Join-Path $PSScriptRoot "Test-ReleasePolicy.ps1"),
    (Join-Path $PSScriptRoot "Test-ReleaseBaseline.ps1")
)) {
    Assert-PowerShellSyntax $script
}

& (Join-Path $PSScriptRoot "Test-ReleasePolicy.ps1")

Assert-True (Test-Path -LiteralPath $ArtifactRoot -PathType Container) "Artifact root missing: $ArtifactRoot"

$nodePath = Join-Path $ArtifactRoot "node.exe"
$dshPackagePath = Join-Path $ArtifactRoot "node_modules\@deepseek-ai\dsh\package.json"
$profileRoot = Join-Path $ArtifactRoot "profile-seed\profiles\web"
$profilePackagePath = Join-Path $profileRoot "package.json"
$directEvidence = @(
    (Join-Path $ArtifactRoot "licenses\OrcaDSH-LICENSE.txt"),
    (Join-Path $ArtifactRoot "licenses\Node-LICENSE.txt"),
    (Join-Path $ArtifactRoot "licenses\WebView2-LICENSE.txt"),
    (Join-Path $ArtifactRoot "licenses\WebView2-NOTICE.txt"),
    (Join-Path $ArtifactRoot "THIRD_PARTY_NOTICES.md"),
    (Join-Path $ArtifactRoot "node_modules\@deepseek-ai\dsh\LICENSE")
)

foreach ($required in @($nodePath, $dshPackagePath, $profilePackagePath) + $directEvidence) {
    Assert-True (Test-Path -LiteralPath $required -PathType Leaf) "Required release file missing: $required"
    Assert-True ((Get-Item -LiteralPath $required).Length -gt 0) "Required release file is empty: $required"
}

$nodeVersion = (& $nodePath --version).Trim()
Assert-True ($nodeVersion -eq "v24.14.0") "Bundled Node version mismatch: $nodeVersion"

$dshPackage = Get-Content -LiteralPath $dshPackagePath -Raw | ConvertFrom-Json
Assert-True ($dshPackage.name -eq "@deepseek-ai/dsh") "Unexpected DSH package name: $($dshPackage.name)"
Assert-True ($dshPackage.version -eq "0.1.0-rc.6") "Unexpected DSH package version: $($dshPackage.version)"

$profilePackage = Get-Content -LiteralPath $profilePackagePath -Raw | ConvertFrom-Json
$bundles = @($profilePackage.dsh.profile.bundles)
$expectedPackages = [ordered]@{
    "dsh-client-liang-intensity-skin" = "0.1.4"
    "orcadsh-state-adapters" = "0.1.0"
    "dsh-client-orca-token-monitor" = "0.1.0"
    "dsh-client-orca-intensity-state" = "0.1.0"
}

foreach ($packageId in $expectedPackages.Keys) {
    Assert-True ($packageId -in $bundles) "Profile bundle missing: $packageId"
    $packageRoot = Join-Path $profileRoot "node_modules\$packageId"
    $packageJsonPath = Join-Path $packageRoot "package.json"
    Assert-True (Test-Path -LiteralPath $packageJsonPath -PathType Leaf) "Bundled package metadata missing: $packageJsonPath"
    $package = Get-Content -LiteralPath $packageJsonPath -Raw | ConvertFrom-Json
    Assert-True ($package.name -eq $packageId) "Bundled package name mismatch at $packageJsonPath"
    Assert-True ($package.version -eq $expectedPackages[$packageId]) "Bundled package version mismatch for ${packageId}: $($package.version)"
    Assert-True (Test-Path -LiteralPath (Join-Path $packageRoot "cordis.patch.yml") -PathType Leaf) "Bundle patch missing for $packageId"
}

Assert-True (Test-Path -LiteralPath (Join-Path $profileRoot "node_modules\dsh-client-orca-token-monitor\lib\client.js") -PathType Leaf) "Token Monitor client entry missing."
Assert-True (Test-Path -LiteralPath (Join-Path $profileRoot "node_modules\orcadsh-state-adapters\src\plugin.js") -PathType Leaf) "State adapter host entry missing."
Assert-True (Test-Path -LiteralPath (Join-Path $profileRoot "node_modules\dsh-client-orca-intensity-state\lib\client.js") -PathType Leaf) "Intensity State client entry missing."

$unsafeFiles = Get-ChildItem -LiteralPath (Join-Path $ArtifactRoot "profile-seed") -Recurse -Force -ErrorAction Stop | Where-Object {
    $outsideNodeModules = $_.FullName -notmatch "[\\/]node_modules[\\/]"
    $sensitiveName = $_.Name -in @(".credentials.yaml", ".env", "credentials.yaml") -or $_.Name -like "*.log"
    $runtimeDataDir = $_.PSIsContainer -and $_.Name -in @("sessions", "logs", "user-data")
    $outsideNodeModules -and ($sensitiveName -or $runtimeDataDir)
}
Assert-True (-not $unsafeFiles) "Profile seed contains user/runtime data: $($unsafeFiles.FullName -join ', ')"

$metadataFiles = Get-ChildItem -LiteralPath (Join-Path $ArtifactRoot "profile-seed") -Recurse -File | Where-Object {
    $_.FullName -notmatch "[\\/]node_modules[\\/]" -or $_.Name -in @("package.json", "cordis.patch.yml")
}
foreach ($file in $metadataFiles) {
    $raw = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
    if ($raw -match "(?i)\b(sk-[A-Za-z0-9_-]{20,}|Bearer\s+[A-Za-z0-9._-]{20,})") {
        throw "Potential credential found in release metadata: $($file.FullName)"
    }
}

Write-Host "Release baseline validation: PASS"
Write-Host " - Node: $nodeVersion"
Write-Host " - DSH: $($dshPackage.version)"
Write-Host " - Bundles: $($expectedPackages.Keys -join ', ')"
Write-Host " - Profile seed user-data scan: PASS"
Write-Host " - Direct redistributed component evidence: PASS (not a full dependency license audit)"
