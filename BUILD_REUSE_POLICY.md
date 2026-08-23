# OrcaDSH Build / Reuse Policy

状态：Canonical  
更新日期：2026-08-20

## 决策类别

### REUSE

直接使用精确版本的上游或社区实现。Orca 负责兼容、配置、许可和 E2E，不复制核心代码。

### FORK

仅当 Orca 差异无法通过配置、主题或小型 adapter 实现时，基于明确版本维护受限分支。Fork 必须有退出策略和持续同步成本预算。

### ADAPT

保留稳定 Orca-facing contract，以薄层连接 DSH 或社区实现。Adapter 不得演变为第二套通用 framework。

### BUILD

Orca 自行拥有与其发行、兼容质量或专属体验直接相关的能力。

### SKIP

当前不开发、不默认集成。重新开启需要新的产品证据、许可结论和决策记录。

## 决策原则

- DSH 语义优先于 Orca 自定义语义。
- 成熟公共能力优先 REUSE；Orca 差异优先 BUILD。
- ADAPT 必须显著小于被适配能力本身。
- FORK 是最后手段，不能仅因为自研更方便或更有控制感。
- 任何默认 bundle 都必须同时通过许可、兼容、离线和真实 E2E gate。

## 能力矩阵

| Capability | Decision | 当前结论 |
| --- | --- | --- |
| Windows Desktop | BUILD + ADAPT | 保留 WinForms + WebView2 reference host；借鉴社区 lifecycle/contract 原则，不迁移 Electron。 |
| Installer | BUILD | 保留 Orca NSIS 用户级安装和卸载。 |
| Bundled Runtime | BUILD | 保留 private Node、固定 DSH 和离线运行能力。 |
| Profile Migration | BUILD | 只迁移 Orca-owned bundles，不能成为通用 package manager。 |
| Token Monitor | ADAPT | 保留 MVP 和 projection consumer；停止扩建 telemetry/analytics。 |
| Context Monitor | DEFER | R1.2 已验证 `dsh-context@0.19.1` 的普通 rc.6 Context UI、projection、语义与回放，但其项目过新、硬 peer 指向 rc.8，且标准安装会重整并显著扩大 profile 依赖图。当前不 bundle，也不写 Orca Context Dashboard。 |
| Metrics Adapter | ADAPT | 保留 snapshot contract，未来缩薄 event parsing。 |
| Activity Adapter | ADAPT | 保留稳定 enum，mapping 可改为官方/社区 projection。 |
| Web Pet | REUSE / FORK | R1 优先评估 `dsh-pet`；只有 Orca renderer 差异明确时才受限 Fork。 |
| Desktop Pet | SKIP | Web Pet 和 state contract 尚未稳定；不引入 native overlay 复杂度。 |
| Skin | REUSE | 优先兼容社区 Skin Center；不建第二套 skin system。 |
| Theme | REUSE | 使用 DSH/社区 theme 能力，Orca 只拥有视觉设计和配置。 |
| Wallpaper | REUSE | 优先复用社区 wallpaper/skin 能力，素材逐项审计。 |
| IntensityState | BUILD | 建立极薄的 Orca presentation contract，内部归一化为 `0..1`。 |
| Reasoning Effort UI | ADAPT | 借鉴 Liang/TUI 交互，始终提交 DSH 原始 effort ID。 |
| Auto Routing | SKIP | 当前不做；未来只能从实验性 recommendation 开始。 |
| Plugin Manager | DEFER | R1.1 已验证 `dshmarket@1.16.0` 的普通 rc.6 Web UI 与隔离 lifecycle，但当前 Orca private runtime 不含其安装动作所需的 pnpm/npm/corepack；上游项目与 release hygiene 仍过新。不得默认 bundle，也不自建 generic manager。 |
| Settings | REUSE | 使用 DSH settings / 社区 settings，不建 generic framework。 |
| Historical Stats | SKIP | 不建立历史 analytics 数据库。 |
| Cost Monitor | SKIP | 当前没有差异化产品需求；未来有证据时再评估 ADAPT。 |
| Auto Update | ADAPT later | 未来只考虑 Orca 发行更新，不造通用插件更新器。 |
| Runtime Injector | SKIP | loader 兼容和许可风险高，不进入默认发行。 |

## 第三方准入 gate

第三方项目只有全部通过以下 gate，才可进入默认发行。仅用于临时 R1 spike 时也必须隔离用户生产 DSH_HOME。

### License

- 核对仓库和具体 package 的完整许可证文本。
- 记录 copyright holder、版本或 commit。
- 不以 README 口头声明替代许可证文件。

### Asset License

- 分开审计图片、视频、字体、声音、角色、肖像和其他媒体。
- 仓库代码许可证不能自动覆盖资产目录。
- 无法证明再分发权的素材不得进入公开 release。

### Compatibility

- 明确支持的 DSH、Node 和 client contract 版本。
- 记录已知 loader、projection、slot、profile 和持久化 seam。

### Exact Version

- 固定 tag、release、package version 或 commit。
- 禁止默认发行依赖浮动 `main`、`latest` 或未固定下载地址。

### Maintenance

- 评估维护活跃度、升级频率、issue 状态和替代方案。
- 对 Fork 明确同步负责人、差异范围和退出条件。

### Offline Bundling

- 最终用户首次启动不需要联网安装插件。
- 不运行用户侧 npm、pnpm、git 或外部安装器。

### Extra Runtime Requirements

- 列出 Node native module、系统服务、浏览器扩展、Electron API、Python、git 或其他额外要求。
- 与 Orca reference host 不兼容的要求必须在准入前解决或明确拒绝。

### Real E2E

- 在隔离 DSH_HOME 验证安装、启动、核心行为、session 切换、刷新恢复、退出和卸载边界。
- “源码看起来兼容”或单元测试不能替代真实 WebView/host smoke。

### Attribution / NOTICE

- 安装包和仓库包含许可证要求的文本、NOTICE、来源、版本和修改说明。
- `THIRD_PARTY_NOTICES.md` 必须与实际 bundle 清单一致。

## 准入结果

每个候选项最终必须记录为：

```text
REUSE / PIN / FORK / REJECT / DEFER
```

并附：精确版本、许可状态、资产许可、安装方式、E2E 证据、已知 seam、默认 bundle 决定和复查日期。

## R1.1 dsh-market decision

`dshmarket@1.16.0`（commit `fa5200829cbcc2a0cb4b5e0d2199f74a26f928fc`）记录为 `DEFER`。直接 package 的 MIT 文本、published tarball 和普通 DSH rc.6 lifecycle 已验证；当前不进入 default/optional bundle。重新评估前必须解决 private pnpm 分发、上游 source reproducibility、社区插件 trust UX、精确依赖许可和安全隔离 E2E。详见 `research/R1_DSH_MARKET_SPIKE.md`。

## R1.2 dsh-context decision

`dsh-context@0.19.1`（commit `aa768c76a1d875a413c13a213262c74f0187930f`）记录为 `DEFER`。直接 package 的 Apache-2.0、普通 DSH rc.6 Host/Client、Context 语义、provider 对照、会话隔离和 projection 回放已验证；当前不进入 default/optional bundle，也不另建 Orca Context Dashboard。只有当 Orca 升级到晚于 rc.6 或与上游 peer 兼容的 DSH、按新基线重新测量 dependency graph、rc.8 peer duplication/profile expansion 不再造成不可接受的分发成本、可安全执行隔离 WinForms/WebView2 E2E，且 direct/transitive license 审计仍可接受时，才重新评估。详见 `research/R1_DSH_CONTEXT_SPIKE.md`。
