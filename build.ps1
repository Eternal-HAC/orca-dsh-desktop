# build.ps1 - 一键构建 OrcaDSH Windows 开发版
# 用法: ./build.ps1  （需要联网；Windows PowerShell / pwsh）
param(
    [string]$DshVersion = "0.1.0-rc.6",
    [string]$WebView2Version = "1.0.4129.50",
    [string]$Version = "0.2.0"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist\DeepSeekHarness"
$lib  = Join-Path $root "dist\_wv2"
$buildDir = Join-Path $root "dist\_dsh-build"
$bundledNodeVersion = "v24.14.0"
$skinPackageId = "dsh-client-liang-intensity-skin"
$skinVersion = "0.1.4"
$skinUrl = "https://github.com/kingOfSoySauce/dsh-liang-skin/releases/download/v$skinVersion/$skinPackageId-$skinVersion.tgz"
$stateAdaptersPackageId = "orcadsh-state-adapters"
$stateAdaptersSource = Join-Path $root "plugins\$stateAdaptersPackageId"
$tokenMonitorPackageId = "dsh-client-orca-token-monitor"
$tokenMonitorSource = Join-Path $root "plugins\$tokenMonitorPackageId"
New-Item -ItemType Directory -Force -Path $dist, $lib, $buildDir | Out-Null

# ---------- 1. node.exe ----------
Write-Host "==> [1/6] bundled Node.js $bundledNodeVersion"
$nodeZip = Join-Path $env:TEMP "node-$bundledNodeVersion-win-x64.zip"
$nodeExtractDir = Join-Path $env:TEMP "node-$bundledNodeVersion-win-x64"
$bundledNodeRoot = Join-Path $nodeExtractDir "node-$bundledNodeVersion-win-x64"
$bundledNodeSource = Join-Path $bundledNodeRoot "node.exe"
$bundledNodeLicense = Join-Path $bundledNodeRoot "LICENSE"
if (-not (Test-Path $bundledNodeSource)) {
    Write-Host "    downloading Node.js $bundledNodeVersion ..."
    Invoke-WebRequest -Uri "https://nodejs.org/dist/$bundledNodeVersion/node-$bundledNodeVersion-win-x64.zip" -OutFile $nodeZip
    Expand-Archive -LiteralPath $nodeZip -DestinationPath $nodeExtractDir -Force
}
if (-not (Test-Path $bundledNodeSource)) { throw "固定 Node.js runtime 缺失：$bundledNodeSource" }
if (-not (Test-Path $bundledNodeLicense)) { throw "固定 Node.js LICENSE 缺失：$bundledNodeLicense" }
$actualBundledNodeVersion = (& $bundledNodeSource --version).Trim()
if ($actualBundledNodeVersion -ne $bundledNodeVersion) {
    throw "固定 Node.js runtime 版本不匹配：预期 $bundledNodeVersion，实际 $actualBundledNodeVersion"
}
Copy-Item -LiteralPath $bundledNodeSource -Destination (Join-Path $dist "node.exe") -Force

# ---------- 2. WebView2 程序集 ----------
Write-Host "==> [2/6] WebView2 assemblies"
$coreDll = Join-Path $lib "Microsoft.Web.WebView2.Core.dll"
$webView2Extract = Join-Path $lib "extract"
$webView2License = Join-Path $webView2Extract "LICENSE.txt"
$webView2Notice = Join-Path $webView2Extract "NOTICE.txt"
if (-not (Test-Path $coreDll) -or -not (Test-Path $webView2License) -or -not (Test-Path $webView2Notice)) {
    $nupkg = Join-Path $lib "webview2.nupkg"
    Write-Host "    downloading Microsoft.Web.WebView2 $WebView2Version ..."
    Invoke-WebRequest -Uri "https://api.nuget.org/v3-flatcontainer/microsoft.web.webview2/$WebView2Version/microsoft.web.webview2.$WebView2Version.nupkg" -OutFile $nupkg
    $zip2 = Join-Path $lib "wv2.zip"
    Copy-Item -LiteralPath $nupkg -Destination $zip2 -Force
    Expand-Archive -LiteralPath $zip2 -DestinationPath (Join-Path $lib "extract") -Force
    Copy-Item -LiteralPath (Join-Path $lib "extract\lib\net462\Microsoft.Web.WebView2.Core.dll") -Destination $lib -Force
    Copy-Item -LiteralPath (Join-Path $lib "extract\lib\net462\Microsoft.Web.WebView2.WinForms.dll") -Destination $lib -Force
    Copy-Item -LiteralPath (Join-Path $lib "extract\runtimes\win-x64\native\WebView2Loader.dll") -Destination $lib -Force
}
Copy-Item -LiteralPath $coreDll -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $lib "Microsoft.Web.WebView2.WinForms.dll") -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $lib "WebView2Loader.dll") -Destination $dist -Force

# ---------- 2b. direct redistribution license evidence ----------
Write-Host "==> [2b] direct redistribution LICENSE / NOTICE"
$licenseDir = Join-Path $dist "licenses"
if (Test-Path $licenseDir) { Remove-Item -LiteralPath $licenseDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $licenseDir | Out-Null
$repositoryLicense = Join-Path $root "LICENSE"
$repositoryNotices = Join-Path $root "THIRD_PARTY_NOTICES.md"
foreach ($requiredLicenseSource in @($repositoryLicense, $repositoryNotices, $bundledNodeLicense, $webView2License, $webView2Notice)) {
    if (-not (Test-Path -LiteralPath $requiredLicenseSource -PathType Leaf)) {
        throw "Direct redistribution license source missing: $requiredLicenseSource"
    }
}
Copy-Item -LiteralPath $repositoryLicense -Destination (Join-Path $licenseDir "OrcaDSH-LICENSE.txt") -Force
Copy-Item -LiteralPath $bundledNodeLicense -Destination (Join-Path $licenseDir "Node-LICENSE.txt") -Force
Copy-Item -LiteralPath $webView2License -Destination (Join-Path $licenseDir "WebView2-LICENSE.txt") -Force
Copy-Item -LiteralPath $webView2Notice -Destination (Join-Path $licenseDir "WebView2-NOTICE.txt") -Force
Copy-Item -LiteralPath $repositoryNotices -Destination (Join-Path $dist "THIRD_PARTY_NOTICES.md") -Force

# ---------- 3. dsh 依赖（扁平布局 node_modules） ----------
Write-Host "==> [3/6] dsh dependencies (node-linker=hoisted)"
$pkg = @{
    name = "dsh-build"; private = $true
    dependencies = @{ "@deepseek-ai/dsh" = $DshVersion }
}
$pkg | ConvertTo-Json -Depth 3 | Set-Content -Encoding ascii -Path (Join-Path $buildDir "package.json")
@"
nodeLinker: hoisted
allowBuilds:
  '@deepseek-ai/dsh-subprocess-local': true
  '@google/genai': true
  koffi: true
  node-pty: true
  protobufjs: true
"@ | Set-Content -Encoding utf8 -Path (Join-Path $buildDir "pnpm-workspace.yaml")

if (-not (Test-Path (Join-Path $buildDir "node_modules\@deepseek-ai\dsh\lib\bin.js"))) {
    # 未检测到 pnpm 时自动安装，省去开发者手动准备的步骤。
    $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
    if (-not $pnpm) {
        if (Get-Command corepack -ErrorAction SilentlyContinue) {
            Write-Host "    未检测到 pnpm，尝试 corepack enable ..."
            & corepack enable 2>$null
            & corepack prepare pnpm@latest --activate 2>$null
            $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
        }
        if (-not $pnpm -and (Get-Command npm -ErrorAction SilentlyContinue)) {
            Write-Host "    尝试 npm i -g pnpm ..."
            & npm i -g pnpm 2>$null
            $pnpm = Get-Command pnpm -ErrorAction SilentlyContinue
        }
    }
    if (-not $pnpm) { throw "未找到 pnpm，且自动安装失败。请先安装 pnpm（npm i -g pnpm 或 corepack enable）。" }
    Write-Host "    使用 pnpm: $($pnpm.Source)"
    Push-Location $buildDir
    try { & $pnpm.Source install --no-frozen-lockfile }
    finally { Pop-Location }
    if ($LASTEXITCODE -ne 0) { throw "pnpm install 失败" }
}
if (Test-Path (Join-Path $dist "node_modules")) { Remove-Item -LiteralPath (Join-Path $dist "node_modules") -Recurse -Force }
Write-Host "    copying node_modules ..."
Copy-Item -LiteralPath (Join-Path $buildDir "node_modules") -Destination (Join-Path $dist "node_modules") -Recurse -Force

# ---------- 3b. 默认 liang skin profile seed ----------
Write-Host "==> [3b] default liang skin $skinVersion profile seed"
$skinTarball = Join-Path $buildDir "$skinPackageId-$skinVersion.tgz"
$seedBuildHome = Join-Path $root "dist\_profile-seed-build"
$profileSeed = Join-Path $dist "profile-seed"
if (-not (Test-Path $skinTarball)) {
    Write-Host "    downloading fixed release: $skinUrl"
    Invoke-WebRequest -Uri $skinUrl -OutFile $skinTarball
}
if (Test-Path $seedBuildHome) { Remove-Item -LiteralPath $seedBuildHome -Recurse -Force }
if (Test-Path $profileSeed) { Remove-Item -LiteralPath $profileSeed -Recurse -Force }
New-Item -ItemType Directory -Force -Path $seedBuildHome | Out-Null

$previousDshHome = $env:DSH_HOME
try {
    $env:DSH_HOME = $seedBuildHome
    # Prefer the public Release URL. A previously downloaded fixed tarball is
    # an offline build fallback; its local path is scrubbed from metadata below.
    & (Join-Path $dist "node.exe") (Join-Path $dist "node_modules\@deepseek-ai\dsh\lib\bin.js") plugin --profile web add $skinUrl
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    fixed skin URL unavailable; retrying with cached tarball"
        & (Join-Path $dist "node.exe") (Join-Path $dist "node_modules\@deepseek-ai\dsh\lib\bin.js") plugin --profile web add $skinTarball
    }
    if ($LASTEXITCODE -ne 0) { throw "dsh plugin add 失败" }
}
finally {
    if ($null -eq $previousDshHome) { Remove-Item Env:DSH_HOME -ErrorAction SilentlyContinue }
    else { $env:DSH_HOME = $previousDshHome }
}

$seedPackageJson = Join-Path $seedBuildHome "profiles\web\package.json"
$seedSkinDir = Join-Path $seedBuildHome "profiles\web\node_modules\$skinPackageId"
if (-not (Test-Path $seedPackageJson) -or -not (Test-Path $seedSkinDir) -or -not (Test-Path $stateAdaptersSource) -or -not (Test-Path $tokenMonitorSource)) {
  throw "默认 skin profile seed 不完整"
}
$seedPackage = Get-Content -LiteralPath $seedPackageJson -Raw | ConvertFrom-Json
$seedPackage.dependencies.PSObject.Properties[$skinPackageId].Value = $skinUrl
if ($skinPackageId -notin @($seedPackage.dsh.profile.bundles)) {
  throw "默认 skin 未写入 dsh.profile.bundles"
}
$seedStateAdaptersDir = Join-Path $seedBuildHome "profiles\web\node_modules\$stateAdaptersPackageId"
New-Item -ItemType Directory -Force -Path $seedStateAdaptersDir | Out-Null
foreach ($runtimeItem in @("package.json", "cordis.patch.yml", "src")) {
    Copy-Item -LiteralPath (Join-Path $stateAdaptersSource $runtimeItem) -Destination $seedStateAdaptersDir -Recurse -Force
}
if (-not (Test-Path (Join-Path $seedStateAdaptersDir "cordis.patch.yml"))) {
    throw "state adapters bundle patch 缺失"
}
if ($stateAdaptersPackageId -notin @($seedPackage.dsh.profile.bundles)) {
    $seedPackage.dsh.profile.bundles += $stateAdaptersPackageId
}
$seedTokenMonitorDir = Join-Path $seedBuildHome "profiles\web\node_modules\$tokenMonitorPackageId"
New-Item -ItemType Directory -Force -Path $seedTokenMonitorDir | Out-Null
foreach ($runtimeItem in @("package.json", "cordis.patch.yml", "src", "lib")) {
    Copy-Item -LiteralPath (Join-Path $tokenMonitorSource $runtimeItem) -Destination $seedTokenMonitorDir -Recurse -Force
}
if ($tokenMonitorPackageId -notin @($seedPackage.dsh.profile.bundles)) {
    $seedPackage.dsh.profile.bundles += $tokenMonitorPackageId
}
$seedPackage | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 -Path $seedPackageJson
# The profile loader consumes package.json, bundle patches, and staged modules;
# lock/workspace files are pnpm build metadata and can retain local paths.
Remove-Item -LiteralPath (Join-Path $seedBuildHome "profiles\web\pnpm-lock.yaml"), (Join-Path $seedBuildHome "profiles\web\pnpm-workspace.yaml") -Force -ErrorAction SilentlyContinue
# This pnpm bookkeeping file has no runtime role in the hoisted profile, yet
# records the build machine's store and virtual-store absolute paths.
$seedModulesMetadata = Join-Path $seedBuildHome "profiles\web\node_modules\.modules.yaml"
Remove-Item -LiteralPath $seedModulesMetadata -Force -ErrorAction SilentlyContinue
$unexpectedSeedFiles = Get-ChildItem -LiteralPath $seedBuildHome -Recurse -File | Where-Object {
    $_.Name -eq ".credentials.yaml" -or $_.Name -like "*.log"
}
if ($unexpectedSeedFiles) {
    throw "profile seed 包含不应发布的用户数据：$($unexpectedSeedFiles.FullName -join ', ')"
}
$seedMetadataFiles = Get-ChildItem -LiteralPath (Join-Path $seedBuildHome "profiles\web") -File |
    Where-Object { $_.Name -in @("package.json", "cordis.patch.yml") }
foreach ($metadataFile in $seedMetadataFiles) {
    if (Select-String -LiteralPath $metadataFile.FullName -Pattern '(?i)\b[A-Z]:[\\/]' -Quiet) {
        throw "profile seed 元数据包含构建机绝对路径：$($metadataFile.FullName)"
    }
}
Copy-Item -LiteralPath $seedBuildHome -Destination $profileSeed -Recurse -Force

# ---------- 4. 编译 exe ----------
Write-Host "==> [4/6] compile DeepSeekHarness.exe"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { $csc = (Get-Command csc -ErrorAction SilentlyContinue).Source }
if (-not $csc) { throw "未找到 csc.exe（需要 .NET Framework 4.8，Windows 自带）" }
& $csc /nologo /target:winexe /platform:x64 /optimize+ `
    "/win32icon:$root\icons\DeepSeekHarness.ico" `
    "/out:$dist\DeepSeekHarness.exe" `
    /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Management.dll /r:System.Web.Extensions.dll `
    "/r:$coreDll" `
    "/r:$lib\Microsoft.Web.WebView2.WinForms.dll" `
    "$root\src\App.cs"
if ($LASTEXITCODE -ne 0) { throw "csc 编译失败" }
Copy-Item -LiteralPath (Join-Path $root "icons\DeepSeekHarness.ico") -Destination (Join-Path $dist "DeepSeekHarness.ico") -Force

# ---------- 5. 使用说明 ----------
Write-Host "==> [5/6] write 使用说明.txt"
@"
OrcaDSH Windows 开发构建
========================
1. 双击 DeepSeekHarness.exe 即可使用
   （或双击「install.bat / 一键安装.bat」自动在桌面与开始菜单创建快捷方式）
2. 首次打开请在界面中配置 DeepSeek API Key
3. 点击窗口 X 会最小化到系统托盘，DSH 服务继续运行
4. 如需完全退出，请在托盘菜单选择「真正退出」；应用会停止服务并清理进程树

系统要求：Windows 10/11 x64、.NET Framework 4.8 与 WebView2 Evergreen Runtime。
如缺少 WebView2 Runtime，应用启动时会提示从 Microsoft 官方地址下载安装。
请保持整个文件夹完整（node.exe / node_modules / DLL 与 exe 同目录），不要单独移动 exe。
如需卸载，运行 uninstall.bat 删除快捷方式，再删除本文件夹即可。
"@ | Set-Content -Encoding utf8 -Path (Join-Path $dist "使用说明.txt")

# ---------- 5b. 一键安装 / 卸载脚本 ----------
Write-Host "==> [5b] copy install.bat / uninstall.bat"
foreach ($f in @("install.bat", "uninstall.bat")) {
    $src = Join-Path $root $f
    if (Test-Path $src) { Copy-Item -LiteralPath $src -Destination $dist -Force }
}

# ---------- 6. NSIS 安装包 ----------
Write-Host "==> [6/6] NSIS installer (Setup.exe)"
$nsisDir = Join-Path $root "dist\_nsis"
$nsisExe = Join-Path $nsisDir "makensis.exe"
if (-not (Test-Path $nsisExe)) {
    # 优先从 PATH / 常见安装目录定位 makensis（覆盖 choco、官方安装器、用户自定义等场景）
    $candidates = @()
    $p = Get-Command makensis -ErrorAction SilentlyContinue
    if ($p) { $candidates += $p.Source }
    $candidates += @(
        (Join-Path $env:ProgramFiles "NSIS\makensis.exe"),
        (Join-Path ${env:ProgramFiles(x86)} "NSIS\makensis.exe"),
        "C:\Program Files\NSIS\makensis.exe",
        "C:\Program Files (x86)\NSIS\makensis.exe"
    )
    $found = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
    if ($found) {
        $nsisExe = $found
        Write-Host "    找到 makensis: $nsisExe"
    } else {
        Write-Host "    未检测到 makensis，下载 NSIS 便携版 ..."
        $nsisVer = "3.11"
        $nsisZip = Join-Path $env:TEMP "nsis-$nsisVer.zip"
        $urls = @(
            "https://downloads.sourceforge.net/project/nsis/NSIS%203/$nsisVer/nsis-$nsisVer.zip",
            "https://sourceforge.net/projects/nsis/files/NSIS%203/$nsisVer/nsis-$nsisVer.zip/download",
            "https://mirrors.mit.edu/macports/distfiles/nsis/nsis-$nsisVer.zip"
        )
        $ok = $false
        foreach ($u in $urls) {
            try {
                Invoke-WebRequest -Uri $u -OutFile $nsisZip -TimeoutSec 180 -ErrorAction Stop
                $header = [System.IO.File]::ReadAllBytes($nsisZip)[0..1]
                if ((Get-Item $nsisZip).Length -gt 100KB -and $header[0] -eq 0x50 -and $header[1] -eq 0x4B) { $ok = $true; break }
                Remove-Item -LiteralPath $nsisZip -Force -ErrorAction SilentlyContinue
            } catch { Write-Host "    下载失败: $u" }
        }
        if (-not $ok) { throw "NSIS 下载失败，请手动安装 NSIS 后重试（https://nsis.sourceforge.io/Download）。" }
        Expand-Archive -LiteralPath $nsisZip -DestinationPath $nsisDir -Force
        # NSIS 压缩包顶层文件夹为 nsis-3.11/
        $extracted = Join-Path $nsisDir "nsis-$nsisVer"
        if (Test-Path (Join-Path $extracted "makensis.exe")) {
            Get-ChildItem $extracted | ForEach-Object { Move-Item $_.FullName -Destination $nsisDir -Force }
            Remove-Item $extracted -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}
if (-not (Test-Path $nsisExe)) { throw "未找到 makensis.exe" }
$outExe = Join-Path $root "dist\DeepSeekHarness-Setup-v$Version-win-x64.exe"
& $nsisExe "/DVERSION=$Version" "/DAPP_SOURCE=$dist" "/DOUT=$outExe" "$root\installer.nsi"
if ($LASTEXITCODE -ne 0) { throw "NSIS 编译失败" }
Write-Host "    已生成: $outExe"

Write-Host ""
Write-Host "构建完成: $dist"
