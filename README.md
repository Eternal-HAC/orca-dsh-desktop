# DeepSeek Harness Desktop

把 DeepSeek Harness（`@deepseek-ai/dsh`）打包成 **Windows 桌面应用**：自带 Node.js 运行时与全部依赖，双击即用，无需安装 Node / 无需命令行 / 不依赖浏览器。

> 底层是官方开源的 [DeepSeek Harness (dsh)](https://github.com/deepseek-ai/DeepSeek-Harness)（MIT），本项目只是给它加了一个原生桌面壳（C# WinForms + WebView2）。

## 特性

- ✅ **真正独立的 exe**：原生窗口（无地址栏/标签页），基于 WebView2
- ✅ **自包含**：应用目录自带 `node.exe` + 全部 `node_modules`，可整体拷走使用
- ✅ **打开即用**：双击启动 → 自动拉起本地 dsh 服务 → 窗口加载界面
- ✅ **关窗即停**：关闭窗口自动停止服务，不残留后台进程（也会接管并清理异常残留的服务）
- ✅ 零配置：Windows 10/11 自带 .NET Framework 与 WebView2 运行时，无需额外安装

## 下载

从 **Releases** 页面下载最新版：

- `DeepSeekHarness-Desktop-vX.Y.Z-win-x64.zip`（便携版，解压后双击 `DeepSeekHarness.exe` 即可）

## 使用

1. 下载并解压 zip（整个文件夹一起解压，不要只拖 exe 出来）
2. 双击 `DeepSeekHarness.exe`
3. 首次打开在界面中配置你的 DeepSeek API Key
4. 关闭窗口即停止服务

系统要求：Windows 10/11 x64（内置 .NET Framework 4.8 与 WebView2 运行时）。

## 从源码构建

```powershell
# 需要: Windows + PowerShell
./build.ps1
# 产物在 dist\DeepSeekHarness\
./package-release.ps1
# 压缩包在 dist\DeepSeekHarness-Desktop-vX.Y.Z-win-x64.zip
```

构建脚本会自动：下载/复用 Node.js → 用 pnpm 安装 `@deepseek-ai/dsh`（扁平布局）→ 下载 WebView2 程序集 → 用系统 csc 编译 exe。

也可用 GitHub Actions：打 tag 后自动构建并上传到 Release（见 `.github/workflows/release.yml`）。

## 目录结构

```
src/App.cs          桌面壳源码（C# WinForms + WebView2）
src/BUILD.md        手工编译说明
build.ps1           一键构建（生成 dist\DeepSeekHarness\）
package-release.ps1 打包 zip
icons/              应用图标
dist/               构建产物（不入库）
```

## 免责声明

- 本项目为社区封装，与 DeepSeek 官方无隶属关系；底层 Harness 版权归 DeepSeek AI（MIT）。
- 使用需遵守 DeepSeek API 服务条款。
- 第三方组件（Node.js、WebView2、各 npm 包）的许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## License

MIT（详见 [LICENSE](LICENSE)）。
