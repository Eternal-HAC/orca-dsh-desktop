[CmdletBinding()]
param(
    [string]$PolicyPath = (Join-Path (Split-Path -Parent $PSScriptRoot) "release-policy.json"),
    [switch]$RequirePublicReleaseApproval
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $PolicyPath -PathType Leaf)) {
    throw "Release policy file not found: $PolicyPath"
}

try {
    $policy = Get-Content -LiteralPath $PolicyPath -Raw | ConvertFrom-Json
}
catch {
    throw "Release policy is not valid JSON: $PolicyPath`n$($_.Exception.Message)"
}

if ($policy.schemaVersion -ne 1) {
    throw "Unsupported release policy schemaVersion '$($policy.schemaVersion)'; expected 1."
}
if ($policy.publicReleaseApproved -isnot [bool]) {
    throw "release-policy.json must contain boolean publicReleaseApproved."
}

$blockers = @($policy.blockers)
if ($null -eq $policy.blockers) {
    throw "release-policy.json must contain a blockers array."
}
foreach ($blocker in $blockers) {
    if ($blocker -isnot [string] -or [string]::IsNullOrWhiteSpace($blocker)) {
        throw "Every release blocker must be a non-empty string."
    }
}

if ($policy.publicReleaseApproved -and $blockers.Count -gt 0) {
    throw "Release policy is inconsistent: publicReleaseApproved is true while blockers remain."
}
if (-not $policy.publicReleaseApproved -and $blockers.Count -eq 0) {
    throw "Release policy is inconsistent: public release is blocked but no blocker reason is recorded."
}

if ($RequirePublicReleaseApproval -and -not $policy.publicReleaseApproved) {
    $details = ($blockers | ForEach-Object { " - $_" }) -join [Environment]::NewLine
    throw @"
PUBLIC RELEASE BLOCKED by repository-controlled release policy.
$details

Do not bypass this check with a secret or workflow input. Approval requires a reviewed repository change after every blocker is resolved or removed from the public artifact.
"@
}

if ($RequirePublicReleaseApproval) {
    Write-Host "Public release policy: APPROVED"
}
else {
    $state = if ($policy.publicReleaseApproved) { "APPROVED" } else { "BLOCKED" }
    Write-Host "Release policy structure: PASS ($state)"
}
