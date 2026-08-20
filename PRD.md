# OrcaDSH Product Requirements

状态：Canonical  
更新日期：2026-08-20

## 产品定位

OrcaDSH 的长期定位由三个部分组成：

```text
Orca Experience Distribution
+
Curated Compatibility Distribution
+
Lightweight Windows Reference Host
```

OrcaDSH 为 DeepSeek Harness 提供经过选择和验证的组合、统一的 Orca 视觉与交互体验，以及一个开箱即用的轻量 Windows 参考宿主。Windows 桌面壳是交付形式之一，不是长期差异化本身。

OrcaDSH 不以“又一个 Windows DSH wrapper”作为长期产品中心。若需求只是通用桌面运行 DSH，应优先评估现有社区桌面项目；Orca 的持续价值来自兼容性、组合质量和独特体验。

## 核心原则

```text
Upstream owns semantics.
Community owns commodity features.
Orca owns compatibility, composition quality and Orca experience.
```

- Upstream DSH 定义 session、projection、model、settings、profile、bundle、plugin 和持久化语义。
- 成熟社区插件优先承担插件市场、上下文分析、通用设置、通用 Pet、Skin、Theme 和 Wallpaper 等公共能力。
- Orca 负责固定兼容版本、集成验证、许可审计、迁移质量、精选默认组合和 Orca 专属体验。
- Orca 功能尽可能通过标准 DSH 插件机制交付，不修改 DSH core。

## 目标用户

- 希望在 Windows 上零命令行安装并使用 DSH 的用户。
- 重视稳定组合、离线可用、明确数据边界和升级可预测性的用户。
- 希望获得统一 Orca 视觉、状态和交互体验的用户。
- 希望使用经过兼容与许可筛选的社区能力，而不愿自行排查插件组合的用户。

## 用户问题

- DSH 和社区插件处于快速演化期，版本、安装方式和 client contract 容易失配。
- 普通用户不应理解或安装 Node.js、npm、pnpm、Corepack、PowerShell 或本地端口。
- 社区插件的代码许可、素材许可和再分发条件可能不同，不能仅凭包名或 `package.json.license` 判断。
- Pet、Skin、Wallpaper、Metrics 和 Agent activity 若各自定义状态，会造成体验割裂和重复维护。

## 核心价值

### Curated compatibility

- 固定 DSH、Node、WebView2 SDK 与所选插件版本。
- 为已支持组合维护人工可读的兼容矩阵和真实 E2E 证据。
- 明确升级 seam，采用 deliberate upgrade，不承诺所有历史 DSH rc。

### Zero-setup Windows delivery

- 私有 bundled Node 和完整 runtime。
- WinForms + WebView2 reference host。
- 用户级 NSIS 安装、桌面快捷方式和正常卸载。
- 独立 DSH_HOME，卸载默认保留凭据、配置和会话。

### Orca experience

- Orca 视觉语言、角色、素材和交互。
- 面向 presentation consumer 的轻量 Activity、Metrics 和未来 Intensity contract。
- Orca-owned Web capabilities 原则上可在标准 `dsh web` 中运行，不硬依赖 WinForms。

## 当前产品基线

- DSH `0.1.0-rc.6`。
- Node.js `24.14.0` 私有 runtime。
- WinForms + WebView2 Windows reference host。
- 独立 `%LOCALAPPDATA%\OrcaDSH`。
- Orca Metrics / Activity projections。
- 当前会话 Token Monitor MVP。
- Orca-owned bundle 增量迁移。

当前 Liang Intensity Skin 仅属于已验证的过渡集成。其公开许可和人物素材再分发授权链尚不完整，因此不能被视为长期不可替换的 Orca 基础依赖或已批准公开发行内容。

## 非目标

- Fork 或修改 DSH core。
- 支持所有历史 DSH rc 和磁盘格式。
- 通用插件市场、通用 Settings framework 或第二套 DSH SDK。
- 自研 Context Dashboard、通用 Skin/Theme/Wallpaper framework 或通用 Web Pet engine。
- 当前阶段开发 Desktop Pet、Auto Routing、历史 Analytics、费用数据库或新的 telemetry framework。
- 要求第三方社区插件依赖 Orca State。
- 在用户机器运行 npm、pnpm、git 或联网安装默认 bundle。

## 成功标准

- Orca-owned Web capabilities 在固定 DSH 版本上通过标准插件/profile 机制运行。
- Windows 用户无需系统 Node/npm/pnpm/git 即可安装、启动、对话和卸载。
- fresh install 与 existing-profile upgrade 均保留用户数据并通过 E2E。
- 每个默认分发的第三方组件都有精确版本、兼容结果、代码与素材许可、NOTICE/attribution 记录。
- Orca compatibility layer 保持小而明确，不复制 DSH session model 或社区通用功能。
- 正式 release 前不存在未关闭的再分发或关键兼容 blocker。

## 相关文档

- 架构边界：[ARCHITECTURE.md](ARCHITECTURE.md)
- 决策记录：[DECISIONS.md](DECISIONS.md)
- Build/Reuse 政策：[BUILD_REUSE_POLICY.md](BUILD_REUSE_POLICY.md)
- 阶段路线：[ROADMAP.md](ROADMAP.md)
- 当前状态：[PROJECT_STATUS.md](PROJECT_STATUS.md)
- 兼容基线：[ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md)
