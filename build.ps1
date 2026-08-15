# build.ps1 - 一键构建 DeepSeek Harness Desktop 便携版
# 用法: ./build.ps1  （需要联网；Windows PowerShell / pwsh）
param(
    [string]$DshVersion = "0.1.0-rc.6",
    [string]$WebView2Version = "1.0.4129.50"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root "dist\DeepSeekHarness"
$lib  = Join-Path $root "dist\_wv2"
$buildDir = Join-Path $root "dist\_dsh-build"
New-Item -ItemType Directory -Force -Path $dist, $lib, $buildDir | Out-Null

# ---------- 1. node.exe ----------
Write-Host "==> [1/5] node.exe"
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCmd) {
    Copy-Item -LiteralPath $nodeCmd.Source -Destination (Join-Path $dist "node.exe") -Force
    Write-Host "    copied from PATH: $($nodeCmd.Source)"
} else {
    $nodeVer = "v24.14.0"
    $tmpZip = Join-Path $env:TEMP "node-$nodeVer-win-x64.zip"
    $tmpDir = Join-Path $env:TEMP "node-$nodeVer-win-x64"
    if (-not (Test-Path (Join-Path $tmpDir "node.exe"))) {
        Write-Host "    downloading Node.js $nodeVer ..."
        Invoke-WebRequest -Uri "https://nodejs.org/dist/$nodeVer/node-$nodeVer-win-x64.zip" -OutFile $tmpZip
        Expand-Archive -LiteralPath $tmpZip -DestinationPath $tmpDir -Force
    }
    Copy-Item -LiteralPath (Join-Path $tmpDir "node.exe") -Destination (Join-Path $dist "node.exe") -Force
}

# ---------- 2. WebView2 程序集 ----------
Write-Host "==> [2/5] WebView2 assemblies"
$coreDll = Join-Path $lib "Microsoft.Web.WebView2.Core.dll"
if (-not (Test-Path $coreDll)) {
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

# ---------- 3. dsh 依赖（扁平布局 node_modules） ----------
Write-Host "==> [3/5] dsh dependencies (node-linker=hoisted)"
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

# ---------- 4. 编译 exe ----------
Write-Host "==> [4/5] compile DeepSeekHarness.exe"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $csc)) { $csc = (Get-Command csc -ErrorAction SilentlyContinue).Source }
if (-not $csc) { throw "未找到 csc.exe（需要 .NET Framework 4.8，Windows 自带）" }
& $csc /nologo /target:winexe /platform:x64 /optimize+ `
    "/win32icon:$root\icons\DeepSeekHarness.ico" `
    "/out:$dist\DeepSeekHarness.exe" `
    /r:System.dll /r:System.Core.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Management.dll `
    "/r:$coreDll" `
    "/r:$lib\Microsoft.Web.WebView2.WinForms.dll" `
    "$root\src\App.cs"
if ($LASTEXITCODE -ne 0) { throw "csc 编译失败" }
Copy-Item -LiteralPath (Join-Path $root "icons\DeepSeekHarness.ico") -Destination (Join-Path $dist "DeepSeekHarness.ico") -Force

# ---------- 5. 使用说明 ----------
Write-Host "==> [5/5] write 使用说明.txt"
@"
DeepSeek Harness 桌面版
========================
1. 双击 DeepSeekHarness.exe 即可使用
   （或双击「install.bat / 一键安装.bat」自动在桌面与开始菜单创建快捷方式）
2. 首次打开请在界面中配置 DeepSeek API Key
3. 关闭窗口即停止服务

系统要求：Windows 10/11 x64（自带 .NET Framework 4.8 与 WebView2 运行时）。
请保持整个文件夹完整（node.exe / node_modules / DLL 与 exe 同目录），不要单独移动 exe。
如需卸载，运行 uninstall.bat 删除快捷方式，再删除本文件夹即可。
"@ | Set-Content -Encoding utf8 -Path (Join-Path $dist "使用说明.txt")

# ---------- 5b. 一键安装 / 卸载脚本 ----------
Write-Host "==> [5/5] copy install.bat / uninstall.bat"
foreach ($f in @("install.bat", "uninstall.bat")) {
    $src = Join-Path $root $f
    if (Test-Path $src) { Copy-Item -LiteralPath $src -Destination $dist -Force }
}

Write-Host ""
Write-Host "构建完成: $dist"
