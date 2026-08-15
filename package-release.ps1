# package-release.ps1 - 把 dist\DeepSeekHarness 打包成 zip（含 DeepSeekHarness/ 外层文件夹）
# 使用系统自带 tar（bsdtar），压缩较慢属正常，请耐心等待。
param([string]$Version = "0.1.0")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist"
$appDir = Join-Path $dist "DeepSeekHarness"
if (-not (Test-Path (Join-Path $appDir "DeepSeekHarness.exe"))) { throw "请先运行 build.ps1" }
$zip = Join-Path $dist "DeepSeekHarness-Desktop-v$Version-win-x64.zip"
if (Test-Path $zip) { Remove-Item -LiteralPath $zip -Force }
Write-Host "打包中（约需 10-15 分钟，请勿关闭）..."
tar -a -c -f $zip -C $dist DeepSeekHarness
if ($LASTEXITCODE -ne 0) { throw "tar 打包失败" }
$mb = [math]::Round((Get-Item $zip).Length / 1MB, 1)
Write-Host "已生成: $zip ($mb MB)"
