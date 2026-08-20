# Changelog

OrcaDSH 的重要开发变化记录在本文件中。当前尚未声明或发布任何正式 OrcaDSH 版本；版本语义和 release gate 未关闭前，所有 Orca 工作统一记录在 `[Unreleased]`。

格式参考 [Keep a Changelog](https://keepachangelog.com/)。本文件中的 imported upstream version 不代表 OrcaDSH release 或 tag。

## [Unreleased]

### Added

- 以 `baiqingyuan/deepseek-harness_Desktop` 为 Windows reference host 基线，建立 OrcaDSH 独立产品路线和 canonical project documentation。
- 固定 bundled Node.js `v24.14.0` 与 `@deepseek-ai/dsh@0.1.0-rc.6`。
- 使用 `%LOCALAPPDATA%\OrcaDSH` 作为独立 DSH_HOME，并由用户级 NSIS Setup 安装到 `%LOCALAPPDATA%\Programs\OrcaDSH`。
- 通过 DSH profile seed 预置 Orca-owned `orcadsh-state-adapters` 和 `dsh-client-orca-token-monitor`。
- 增加 per-session Metrics / Activity projections 和 Token Monitor MVP。
- 为已有 web profile 增加只迁移 Orca-owned bundles 的增量 migration。
- 建立 release/legal/compatibility policy、人工兼容矩阵和 release regression checklist。

### Changed

- 产品定位调整为 Orca Experience Distribution、Curated Compatibility Distribution 和 Lightweight Windows Reference Host。
- README、构建说明和第三方声明开始使用 OrcaDSH 身份，并区分用户体验名称与 legacy runtime filename。
- 明确窗口 `X` 最小化到托盘；托盘“真正退出”才停止 DSH 并清理进程树。

### Release blockers

- `dsh-client-liang-intensity-skin@0.1.4` 仅用于 development compatibility testing；代码和媒体素材再分发证据未解决，正式公开 release 被阻塞。
- 直接分发组件和 transitive npm dependency 的完整许可证打包审计尚未完成。
- GitHub Actions 仍可由 `v*` tag 或手动 workflow 直接创建 Release，尚未加入法律 gate。

## Imported upstream history / pre-Orca baseline

以下记录来自导入的 [`baiqingyuan/deepseek-harness_Desktop`](https://github.com/baiqingyuan/deepseek-harness_Desktop) 历史，覆盖仓库提交 `924f4db` 至 Orca 导入锚点 `cf047b5`。它们描述的是 pre-Orca Windows desktop baseline，保留用于 attribution 和实现溯源。

这些版本号、发布日期和历史发布声明不属于 OrcaDSH，也不证明 Eternal-HAC/orca-dsh-desktop 曾发布相应 release 或 tag。

### [Imported upstream 0.3.0] - 2026-08-16

- 将窗口关闭行为改为最小化到系统托盘并保持 DSH 运行。
- 增加托盘“真正退出”菜单，显式退出时清理 DSH 进程树。
- 单实例逻辑兼容隐藏窗口，托盘恢复随后改为单击触发。

### [Imported upstream 0.2.0] - 2026-08-16

- 将同步启动等待改为 async/await，减少 UI 启动冻结。
- 增加进程树清理、单实例保护、端口冲突提示、WebView2 缺失引导和错误日志。
- 增加便携脚本、NSIS Setup、CI 构建/发布流程和固定 DSH/WebView2/Node 版本的早期实现。

### [Imported upstream 0.1.0]

- 初始 WinForms + WebView2 desktop shell。
- 自包含 Node.js runtime 与 DSH `node_modules`。
- 初始端口探测、服务启动、便携打包与 GitHub Actions。

导入后的 OrcaDSH 决策和阶段路线以 [DECISIONS.md](DECISIONS.md) 与 [ROADMAP.md](ROADMAP.md) 为准，不沿用 imported upstream roadmap。
