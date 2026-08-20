# OrcaDSH Windows 构建说明

本文以当前 `build.ps1` 和 `src/App.cs` 为准。`DeepSeekHarness.exe`、`dist/DeepSeekHarness` 等名称是当前仍保留的 legacy technical identifier；本轮没有重命名 runtime 或 installer 标识。

## 推荐构建

在仓库根目录执行：

```powershell
./build.ps1
```

默认固定版本：

- `@deepseek-ai/dsh@0.1.0-rc.6`
- Node.js `v24.14.0` Windows x64 runtime
- Microsoft WebView2 SDK `1.0.4129.50`
- development Liang package `dsh-client-liang-intensity-skin@0.1.4`

构建机要求：

- Windows x64 与 PowerShell。
- 可用的 .NET Framework 4.8 C# compiler，默认路径为 `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`。
- 联网访问 Node.js、NuGet、npm registry、固定 Liang release tarball 和必要时的 NSIS 下载源。
- 可用的 Node.js 构建环境和 pnpm。未找到 pnpm 时，脚本会尝试 `corepack`，随后尝试使用 npm 全局安装 pnpm。

构建机上的 Node/pnpm 只用于安装和准备依赖。发行目录中的 `node.exe` 始终来自脚本下载并验证的固定 Node.js `v24.14.0` archive，不从构建机 PATH 复制。

## build.ps1 当前行为

脚本依次执行：

1. 下载并验证固定 Node.js runtime，然后复制 `node.exe`。
2. 下载 WebView2 NuGet package，提取 Core、WinForms 和 native Loader DLL。
3. 使用 pnpm 的 hoisted layout 安装固定 DSH runtime。
4. 在隔离临时 DSH_HOME 中生成 web profile seed，加入当前 development Liang package 和 Orca-owned bundles，并清理凭据、会话、日志及已知构建机路径 metadata。
5. 使用 .NET Framework C# compiler 编译 WinForms host。
6. 写入开发构建用户说明和便携快捷方式脚本。
7. 定位或下载 NSIS，生成用户级 Setup。

主要产物：

```text
dist\DeepSeekHarness\
dist\DeepSeekHarness-Setup-v<version>-win-x64.exe
```

应用目录包含 `DeepSeekHarness.exe`、固定 `node.exe`、`node_modules`、`profile-seed` 和 WebView2 SDK DLL。最终用户不需要 Node、npm、pnpm 或 git。

构建成功只说明 pipeline 完成，不代表产物已通过正式公开发行所需的许可和回归 gate。参见根目录 `THIRD_PARTY_NOTICES.md` 与 `RELEASE_CHECKLIST.md`。

## 手工编译 WinForms host

手工编译适合只验证 `src/App.cs` 的 C# 编译，不会准备 bundled Node、DSH、profile seed 或 NSIS Setup。

当前 `App.cs` 直接使用：

- WinForms / Drawing / Core framework assemblies。
- `System.Management.dll`，用于进程树枚举和清理。
- `System.Web.Extensions.dll`，用于 existing-profile bundle migration 的 `JavaScriptSerializer`。
- WebView2 Core 与 WinForms managed assemblies。

示例：

```powershell
$repo = "F:\path\to\orca-dsh-desktop"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$wv2 = Join-Path $repo "dist\_wv2"
$out = Join-Path $repo "dist\DeepSeekHarness"

& $csc /nologo /target:winexe /platform:x64 /optimize+ `
  "/win32icon:$repo\icons\DeepSeekHarness.ico" `
  "/out:$out\DeepSeekHarness.exe" `
  /r:System.dll `
  /r:System.Core.dll `
  /r:System.Drawing.dll `
  /r:System.Windows.Forms.dll `
  /r:System.Management.dll `
  /r:System.Web.Extensions.dll `
  "/r:$wv2\Microsoft.Web.WebView2.Core.dll" `
  "/r:$wv2\Microsoft.Web.WebView2.WinForms.dll" `
  "$repo\src\App.cs"

if ($LASTEXITCODE -ne 0) { throw "csc compile failed" }
```

手工编译后的运行目录还必须包含：

- `node.exe`
- `node_modules\@deepseek-ai\dsh\lib\bin.js` 及完整 runtime dependencies
- `profile-seed\`，用于 Orca-owned profile 初始化和 migration
- `Microsoft.Web.WebView2.Core.dll`
- `Microsoft.Web.WebView2.WinForms.dll`
- `WebView2Loader.dll`
- `DeepSeekHarness.ico`

目标系统需要 .NET Framework 4.8 和 Microsoft Edge WebView2 Evergreen Runtime。WebView2 Runtime 缺失时，当前应用会提示通过 Microsoft 官方 bootstrapper 下载；Runtime 本身不由当前 Setup 捆绑。

## Runtime paths and behavior

- 安装目录：`%LOCALAPPDATA%\Programs\OrcaDSH`
- DSH_HOME：`%LOCALAPPDATA%\OrcaDSH`
- WebView URL：`http://127.0.0.1:3080`
- 点击窗口 `X`：隐藏到托盘，DSH 继续运行。
- 托盘“真正退出”：停止本应用启动或接管的 DSH，并清理进程树。
