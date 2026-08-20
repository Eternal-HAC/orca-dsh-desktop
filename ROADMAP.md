# OrcaDSH Roadmap

状态：Canonical  
更新日期：2026-08-20

旧的 P1/P2“继续新增自研功能”路线已废弃。当前路线以法律与兼容证据为前置条件，以标准 DSH Web 插件形式交付 Orca experience。

## R0 — Route Freeze / Release Hygiene

### Goal

冻结新路线，修复项目身份、文档、许可和兼容证据，使仓库具备可审查的 release gate。

### Scope

- R0.1：建立 canonical project documentation。
- R0.2：修正 README、CHANGELOG、THIRD_PARTY_NOTICES、BUILD 文档与产品身份漂移。
- 审计 Liang 代码与人物素材授权，获得许可或制定替换/移除方案。
- 固化 existing-profile、session switching、estimated→exact、Liang coexistence 和 zero-orphan regression。
- 建立人工可维护的兼容矩阵。

### Out of Scope

- 新功能、社区插件安装、IntensityState、Pet、routing、release 打包或发布。

### Entry Criteria

- P0.9.1 完成并有真实 WebView E2E。
- 当前 Git baseline 可确认。
- 新路线经项目所有者批准。

### Exit Criteria

- Canonical 文档职责清晰，无现行路线冲突。
- README/notice/build 文档与实际项目一致。
- Liang blocker 有明确关闭结果或从 release 内容移除。
- release regression 和兼容基线可重复执行。

### Artifacts

- `PRD.md`、`ARCHITECTURE.md`、`DECISIONS.md`。
- `BUILD_REUSE_POLICY.md`、`ROADMAP.md`。
- `PROJECT_STATUS.md`、`ORCA_COMPATIBILITY.md`。
- 更新后的 release/legal hygiene 文档与回归记录。

## R1 — Community Integration Spikes

### Goal

用真实 host E2E 判断 Orca 是否能可靠承载选定社区能力，并形成 REUSE/PIN/FORK/REJECT 结论。

### Scope

只验证：

```text
dsh-market
dsh-context
dsh-pet
```

- 使用临时/开发 DSH_HOME。
- 手工或开发流程安装，记录精确版本和依赖。
- 核对 license、asset license、runtime requirement 和 attribution。
- 验证普通 `dsh web` 与 Orca reference host 行为。

### Out of Scope

- 默认 bundle、生产 DSH_HOME 迁移、插件市场自研、Orca Pet、Skin 改造和 installer 修改。

### Entry Criteria

- R0 release/legal policy 完成。
- 三个候选项目的精确版本和初步许可材料可取得。
- 隔离测试方案获批准。

### Exit Criteria

- 每个候选都有 REUSE/PIN/FORK/REJECT/DEFER 结果。
- E2E、兼容 seam、失败模式和许可义务均有记录。
- 没有候选被隐式加入默认发行。

### Artifacts

- 三份 integration spike 记录。
- 更新后的 `ORCA_COMPATIBILITY.md`。
- 更新后的 Build/Reuse 决策。

## R2 — Thin State Contract

### Goal

定义最小 Orca presentation state，并明确 Metrics/Activity 的长期 thin adapter 边界。

### Scope

- 设计 `OrcaIntensityState v0`：`effortId`、`normalizedIntensity`、nullable preview、source。
- 分离 selected 与 recommended intensity。
- 审查 Metrics/Activity 是否可消费可靠官方/社区 projection。
- 规定 multi-session 和 active-session selector。

### Out of Scope

- Router、history、费用、动画 framework、Pet renderer、wallpaper engine 和 auto apply。

### Entry Criteria

- Metrics / Activity 已有足够的官方、社区或 Orca runtime evidence，可支撑 thin-adapter review。
- Intensity consumer 和 portability 要求明确。

### Exit Criteria

- Contract 小而稳定，未泄漏 Liang 0–30 刻度。
- 普通 DSH plugin 可消费，不依赖 WinForms。
- mapping、null、preview 和 source 语义有测试计划。

### Artifacts

- Intensity contract specification。
- Metrics/Activity adapter decision update。
- compatibility smoke additions。

## R3 — Orca Web Experience MVP

### Goal

用合法、可移植的素材和标准 DSH Web 插件形成首个真正差异化的 Orca experience。

### Scope

- Orca visual identity、角色和专属交互。
- 根据 R1 结果 REUSE 或受限 FORK Web Pet。
- 兼容社区 Skin Center，不建立通用 skin framework。
- Activity、Intensity 和必要 Metrics 驱动 Orca presentation。
- 在标准 `dsh web` 与 Orca reference host 中验证。

### Out of Scope

- Desktop Pet、Auto Routing、通用 Plugin Manager、历史 Analytics、Cost Database。

### Entry Criteria

- R2 contract 通过 review。
- 所有 Orca 素材权利清晰。
- 选定社区组件通过准入 gate。

### Exit Criteria

- Orca Web MVP 不依赖 WinForms 特有 API。
- session 切换、刷新、activity、intensity 与 error state 可恢复。
- 许可、可访问性、性能和 coexistence E2E 通过。

### Artifacts

- Orca Web plugin/package。
- 合法素材与 attribution 清单。
- Web E2E evidence。

## R4 — Curated Distribution Release

### Goal

把经验证的 DSH、社区能力和 Orca experience 组合为可公开发行的精选 Windows distribution。

### Scope

- 固定所有默认组件版本。
- 完成许可 allowlist、NOTICE 和 release notes。
- fresh install、existing-profile upgrade、API 对话、session A/B、退出、重启和卸载回归。
- 构建 Setup 和发布候选验证。

### Out of Scope

- 未经 R1/R2/R3 验证的新插件。
- 通用插件更新器、Desktop Pet、Auto Routing 和所有历史 DSH rc 支持。

### Entry Criteria

- R0 legal blockers 全部关闭。
- R1–R3 所选组件通过兼容和许可 gate。
- 没有未确认的代码、素材或 transitive asset 授权。

### Exit Criteria

- 安装包内容与 notices/compatibility matrix 完全一致。
- 全部 release smoke PASS，用户数据升级和卸载边界正确。
- 项目所有者明确批准发布。

### Artifacts

- Curated compatibility manifest 的稳定人类可读版本。
- Release candidate、哈希、测试记录、notices 和 release notes。
