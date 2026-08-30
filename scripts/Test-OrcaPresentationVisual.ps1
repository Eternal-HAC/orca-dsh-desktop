[CmdletBinding()]
param(
    [int]$Port = 3445,
    [int]$TimeoutSeconds = 45,
    [string]$OutputDirectory = (Join-Path ([System.IO.Path]::GetTempPath()) ("orcadsh-r32-visual-" + [Guid]::NewGuid().ToString("N")))
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$artifact = Join-Path $root "dist\DeepSeekHarness"
$harnessSource = Join-Path $root "tests\OrcaWebView2Harness\Program.cs"
$harnessDir = Join-Path $OutputDirectory "harness"
$dshHome = Join-Path $OutputDirectory "dsh-home"
$webEvidence = Join-Path $OutputDirectory "evidence"
$node = Join-Path $artifact "node.exe"
$dsh = Join-Path $artifact "node_modules\@deepseek-ai\dsh\lib\bin.js"
$seed = Join-Path $artifact "profile-seed"
$csc = Join-Path $env:WINDIR "Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$wv2 = Join-Path $root "dist\_wv2"
$server = $null
$serverStdout = Join-Path $OutputDirectory "dsh-stdout.log"
$serverStderr = Join-Path $OutputDirectory "dsh-stderr.log"

function Assert-Path([string]$Path) { if (-not (Test-Path -LiteralPath $Path)) { throw "Required path missing: $Path" } }
function Stop-Tree([int]$ProcessId) {
    Get-CimInstance Win32_Process -Filter "ParentProcessId=$ProcessId" -ErrorAction SilentlyContinue | ForEach-Object { Stop-Tree $_.ProcessId }
    Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
}
function New-IsolatedOrdinarySession([int]$Port, [string]$Output) {
    $rpcId = [Guid]::NewGuid().ToString("N")
    $sessionId = "orca-r32-visual-" + [Guid]::NewGuid().ToString("N")
    $body = @{
        type = "client-request"
        rpcId = $rpcId
        method = "session.create"
        payload = @{ sessionId = $sessionId }
    } | ConvertTo-Json -Compress
    $response = $null
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        try {
            $response = Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:$Port/api/session.create" -ContentType "application/json" -Body $body
            break
        }
        catch {
            if ([DateTime]::UtcNow -ge $deadline) { throw }
            Start-Sleep -Milliseconds 300
        }
    } while ($true)
    $response | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $Output "session-create.json")
    if (-not $response.result.ok -or $response.result.value.sessionId -ne $sessionId) {
        throw "Provider-free isolated session.create did not return the requested session ID."
    }
    return $sessionId
}
function Wait-Port([int]$Port, [int]$Seconds) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try { $client = [Net.Sockets.TcpClient]::new(); $client.Connect("127.0.0.1", $Port); $client.Dispose(); return } catch { Start-Sleep -Milliseconds 250 }
    }
    $details = @()
    foreach ($log in $serverStdout, $serverStderr) {
        if (Test-Path -LiteralPath $log) { $details += Get-Content -Raw -LiteralPath $log }
    }
    throw ("DSH did not listen on isolated port $Port within $Seconds seconds." + [Environment]::NewLine + ($details -join [Environment]::NewLine))
}

Assert-Path $node; Assert-Path $dsh; Assert-Path $seed; Assert-Path $harnessSource; Assert-Path $csc
if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw "Port $Port is already listening." }
New-Item -ItemType Directory -Force -Path $OutputDirectory, $harnessDir, $dshHome, $webEvidence | Out-Null
Copy-Item -LiteralPath (Join-Path $seed "profiles") -Destination $dshHome -Recurse

try {
    $harnessExe = Join-Path $harnessDir "OrcaWebView2Harness.exe"
    $coreReference = Join-Path $wv2 "Microsoft.Web.WebView2.Core.dll"
    $winFormsReference = Join-Path $wv2 "Microsoft.Web.WebView2.WinForms.dll"
    $compilerArguments = @(
        "/nologo",
        "/target:winexe",
        "/out:$harnessExe",
        "/r:System.Windows.Forms.dll",
        "/r:System.Drawing.dll",
        "/r:System.Web.Extensions.dll",
        "/r:$coreReference",
        "/r:$winFormsReference",
        $harnessSource
    )
    & $csc @compilerArguments
    if ($LASTEXITCODE -ne 0) { throw "WebView2 harness compile failed." }
    Copy-Item (Join-Path $wv2 "Microsoft.Web.WebView2.Core.dll"), (Join-Path $wv2 "Microsoft.Web.WebView2.WinForms.dll"), (Join-Path $wv2 "WebView2Loader.dll") -Destination $harnessDir

    $oldHome = $env:DSH_HOME; $env:DSH_HOME = $dshHome
    try { $server = Start-Process -FilePath $node -ArgumentList ('"' + $dsh + '" --profile web --host 127.0.0.1 --port ' + $Port) -WorkingDirectory $artifact -RedirectStandardOutput $serverStdout -RedirectStandardError $serverStderr -PassThru -WindowStyle Hidden } finally { $env:DSH_HOME = $oldHome }
    Wait-Port $Port 30
    $sessionId = New-IsolatedOrdinarySession $Port $OutputDirectory
    Write-Host "Created provider-free isolated ordinary session: $sessionId"
    $harness = Start-Process -FilePath $harnessExe -ArgumentList @("--url", "http://127.0.0.1:$Port", "--output", $webEvidence, "--timeout", $TimeoutSeconds, "--session-id", $sessionId) -PassThru -Wait
    if ($harness.ExitCode -ne 0) { throw "WebView2 harness exited $($harness.ExitCode). Evidence: $webEvidence" }
    $result = Get-Content -Raw (Join-Path $webEvidence "result.json") | ConvertFrom-Json
    if ($result.status -ne "PASS") { throw "WebView2 harness did not report PASS." }
    Write-Host "Orca presentation visual harness: PASS"
    Write-Host "Evidence: $webEvidence"
}
finally {
    if ($server -and -not $server.HasExited) { Stop-Tree $server.Id }
    Start-Sleep -Milliseconds 500
    if (Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue) { throw "Isolated DSH port $Port remained open after cleanup." }
}
