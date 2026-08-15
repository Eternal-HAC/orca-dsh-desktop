# package-release.ps1 - 把 dist\DeepSeekHarness 打包成 zip（含 DeepSeekHarness/ 外层文件夹）
param([string]$Version = "0.1.0")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$appDir = Join-Path $root "dist\DeepSeekHarness"
if (-not (Test-Path (Join-Path $appDir "DeepSeekHarness.exe"))) { throw "请先运行 build.ps1" }
$zip = Join-Path $root "dist\DeepSeekHarness-Desktop-v$Version-win-x64.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$folderName = "DeepSeekHarness"
$fs = [System.IO.File]::Open($zip, [System.IO.FileMode]::Create)
$archive = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    $files = @(Get-ChildItem -LiteralPath $appDir -Recurse -File)
    $count = 0
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($appDir.Length + 1).Replace('\', '/')
        $entry = $archive.CreateEntry("$folderName/$rel", [System.IO.Compression.CompressionLevel]::Optimal)
        $es = $entry.Open()
        $in = [System.IO.File]::OpenRead($f.FullName)
        try { $in.CopyTo($es) } finally { $es.Dispose(); $in.Dispose() }
        $count++
        if ($count % 2000 -eq 0) { Write-Host "  packed $count / $($files.Count)" }
    }
    Write-Host "packed $count files"
} finally {
    $archive.Dispose()
    $fs.Dispose()
}
$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "已生成: $zip ($mb MB)"
