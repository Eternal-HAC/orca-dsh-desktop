# Changelog

本项目所有重要改动记录于此。格式参考 [Keep a Changelog](https://keepachangelog.com/)，版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

## [0.2.0]

> 面向「开箱即用、少部署、少求助」的一次集中打磨：修复了桌面壳的多处运行时缺陷，并大幅简化构建与发布流程。

### 修复 (Fixed)
- **启动期界面卡死（白屏）**：原 `StartServerIfNeeded()` 在 UI 线程同步 `Thread.Sleep` 等待 dsh 服务，最长冻结 90 秒。改为 `async/await + Task.Delay`，启动期间窗口可响应并显示「正在启动本地服务…（已等待 N 秒）」加载提示。
- **关窗残留子进程**：原 `Process.Kill()` 只杀 node 父进程，dsh 衍生的子进程会残留。新增 `KillProcessTree()`，通过 WMI 递归清理整棵进程树，真正做到「关窗即停」。
- **多实例互相误杀**：原逻辑在端口被占用时接管对方进程，关掉第二个实例会把第一个实例的服务也杀掉。新增单实例 `Mutex`，第二个实例仅把已运行窗口提到前台并退出，不再拉起/接管服务。

### 新增 (Added)
- **WebView2 运行时缺失 → 一键引导安装**：启动前自动探测 WebView2 运行时，缺失时弹窗询问「是否立即下载安装」，点「是」后自动静默安装并重新初始化，不再黑屏报错。
- **友好的缺失文件提示**：`node.exe` 或 dsh 文件被杀软误删时，提示文案改为中文并指明去 GitHub Releases 下载完整包。
- **端口占用明确提示**：端口 `3080` 被非本应用进程占用时，明确提示「端口被占用，请关闭占用程序后重试」，避免静默显示他人内容。
- **导航失败提示与错误落盘**：WebView2 初始化失败时弹一次友好提示；原始异常同时写入 `dsh-app-error.log` 便于排查。
- **CI 手动一键发布**：`.github/workflows/release.yml` 新增 `workflow_dispatch` 的 `version` 输入，在 Actions 页面填版本号即可构建并发布，无需先打 tag。

### 变更 (Changed)
- **构建自动化**：`build.ps1` 在未检测到 `pnpm` 时自动 `corepack enable` / `npm i -g pnpm` 兜底，省去「先装 pnpm」这一步。
- **打包自动化**：`package-release.ps1` 在 `dist` 缺失时自动先调用 `build.ps1`，实现「一条命令出包」。
- **文档更新**：`README.md` 补齐运行时自检、一键安装、一条命令构建/发布等说明；`src/BUILD.md` 修正过时的 `desktop\` 路径。
- **锁定依赖版本**：`build.ps1` 固定 `DshVersion = 0.1.0-rc.6`、`WebView2Version = 1.0.4129.50`、`node v24.14.0`，提升可复现性。

## [0.1.0] - 初始版本

- 首个可发布版本：基于 WinForms + WebView2 的桌面壳，封装官方 DeepSeek Harness（`@deepseek-ai/dsh`）。
- 自包含发布包：内置 Node.js 运行时与 `node_modules`，用户无需安装 Node/pnpm。
- 端口探测与异常残留接管清理；WebView2 E_ABORT 重试机制。
- 构建脚本：`build.ps1`、`package-release.ps1`、GitHub Actions 自动构建发布。
