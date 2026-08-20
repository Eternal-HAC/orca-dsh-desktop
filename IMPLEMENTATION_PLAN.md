# OrcaDSH v0.1 P0 实施计划

> **Historical document.** This plan records the original P0 execution sequence, which has now completed through P0.9.1. Current work is governed by [ROADMAP.md](ROADMAP.md), [PROJECT_STATUS.md](PROJECT_STATUS.md), and [BUILD_REUSE_POLICY.md](BUILD_REUSE_POLICY.md). Retained for project history.

日期：2026-08-17

## 验收目标

最终用户安装 `Setup.exe` 后可从桌面快捷方式启动一个 WebView2 桌面窗口；程序使用自带 Node 和 DSH，在本机启动 Web UI。用户无需预装 Node、npm、pnpm 或命令行工具。

## 已批准的阶段顺序

### 阶段 1：上游基线验证（当前）

1. 导入并保留上游基线、许可证和来源。
2. 记录架构审查与本计划。
3. 不改代码、不装 skin，直接运行上游 `build.ps1`。
4. 检查 `dist/DeepSeekHarness` 和 NSIS `Setup.exe`。
5. 运行桌面壳 smoke test：确认 DSH 监听、WebView2 导航、显式退出后的进程清理。

停止条件：报告构建和 smoke test 证据；不进入 skin 集成。

### 阶段 2：独立 DSH_HOME 与预置 skin

1. 在 `src/App.cs` 中将 DSH 子进程的 `DSH_HOME` 指向产品独立用户数据目录。
2. 在 `build.ps1` 中增加构建期 profile seed：锁定 `@deepseek-ai/dsh@0.1.0-rc.6` 与 skin `v0.1.4`。
3. 将 seed 随 `dist/DeepSeekHarness` 打包，并由 `src/App.cs` 在首次启动时初始化，不覆盖既有用户数据。
4. 在 `installer.nsi` 中保持卸载范围仅为 `$INSTDIR` 和快捷方式，显式不删除独立 DSH_HOME。
5. 验证 skin 默认启用、reasoning effort 正常提交、DSH 对话可发送。

### 阶段 3：发行验证

1. 在未预装系统 Node 的 Windows 测试上下文中安装 Setup.exe。
2. 验证桌面和开始菜单快捷方式、启动、显式退出、卸载和用户数据保留。
3. 记录版本、构建环境、产物哈希、已验证项和已知风险。

## 固定边界

- `dsh-liang-skin` 的原版素材先原样使用。
- 不把 API Key、开发者 `.dsh` 数据或 credentials 纳入仓库或安装包。
- 不改变用户 PATH，不依赖用户机器的 Node/npm/pnpm。
- 任何 DSH 或 skin 版本升级都需重新完成集成验证。
