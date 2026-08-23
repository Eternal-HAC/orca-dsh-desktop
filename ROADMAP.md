# OrcaDSH Roadmap

状态：Canonical  
更新日期：2026-08-20

旧的 P1/P2“继续新增自研功能”路线已废弃。当前路线以法律与兼容证据为前置条件，以标准 DSH Web 插件形式交付 Orca experience。

## R0 — Route Freeze / Release Hygiene

阶段状态：**COMPLETE**（2026-08-20）。Public release blockers 和 release-candidate-only verification 按下方 closure disposition 保持开放，不阻止 R1 隔离 spike。

### Goal

冻结新路线，修复项目身份、文档、许可和兼容证据，使仓库具备可审查的 release gate。

### Scope

- R0.1：建立 canonical project documentation。
- R0.2：修正 README、CHANGELOG、THIRD_PARTY_NOTICES、BUILD 文档与产品身份漂移。
- R0.3：用 repository-controlled policy 阻止未经批准的 public release，并把回归分为 automated、manual/E2E、release-only。
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
- `release-policy.json`、release gate 和轻量 baseline/policy validation scripts。

### R0 closure disposition

R0 governance 已完成。以下未关闭事项保留其原有严格要求，不因进入 R1 而弱化：

- **Public release blockers**：Liang 获得明确再分发权或从 public artifact 移除/替换；完成实际 bundled transitive dependency tree 的法律审计。
- **Release-candidate-only verification，defer to R4**：最终 installed-tree LICENSE/NOTICE；restart/reinstall 后 credentials、sessions、config 可读取；候选 Setup version/SHA/commit/evidence 对应。
- `release-policy.json` 在 blocker 关闭前继续默认拒绝 public release。

Next phase 是 R1 Community Integration Spikes。Next Approved Work 仅为 R1.1 `dsh-market` isolated integration spike。R1 仍只允许依次隔离验证 `dsh-market`、`dsh-context`、`dsh-pet`；任何候选都不得因 spike 自动进入默认 bundle。

### Future identity migration plan

Identity migration 不阻塞 R0，本轮不实施。建议按以下顺序单独设计、构建和验证：

1. **显示文案**：窗口标题、托盘文案、installer `APP_NAME`、welcome 文案和 Publisher。影响用户可见身份；installer `APP_NAME` 同时参与 uninstall registry key 与快捷方式路径，不能只当文案替换。
2. **installer compatibility**：先定义旧 `DeepSeek Harness` uninstall key、开始菜单目录、桌面快捷方式和 `%LOCALAPPDATA%\Programs\OrcaDSH` 的升级/清理策略，再迁移 `APP_NAME`。安装目录当前已是 OrcaDSH，优先保持稳定以保护 in-place upgrade。
3. **single-instance and window discovery**：成对迁移 mutex `DeepSeekHarness.Desktop.SingleInstance`、窗口标题和 `FindWindow`。需要兼容旧进程，避免新旧版本并行启动或第二实例无法唤醒第一实例。
4. **executable/icon and cleanup**：迁移 `DeepSeekHarness.exe/.ico` 时同步 compiler output、installer `APP_EXE`、快捷方式、DisplayIcon 和任何 process/path-based cleanup；用 upgrade 与 explicit-exit smoke 验证。
5. **artifact/CI paths**：最后迁移 `dist/DeepSeekHarness`、Setup/ZIP filename、`package-release.ps1` 外层目录和 Actions artifact glob。此层不应先于 build/installer consumers。
6. **technical identifiers**：C# namespace 可独立迁移，用户行为影响低；默认 version 常量应在正式 Orca version policy 确定后统一处理，不能借 identity rename 伪造 release history。

## R1 — Community Integration Spikes

阶段状态：**COMPLETE**（2026-08-23）。三个计划候选均已完成隔离审计并记录为 `DEFER`。`DEFER` 保留重新评估入口，不代表 default/optional bundle、Fork 或 Orca support 获批。

### Goal

用真实 host E2E 判断 Orca 是否能可靠承载选定社区能力，并形成 REUSE/PIN/FORK/REJECT/DEFER 结论。

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

**Status: COMPLETE**

### Goal

在固定 rc.6 baseline 上冻结最小、用户控制优先的 `OrcaIntensityState v0`，让未来合法的 Orca presentation 可以脱离 Liang 的 0–30 刻度而消费真实 DSH reasoning effort。R2 是 contract 和 compatibility scope，不是 Pet、Skin 或视觉资产实现阶段。

### Scope

- 规定 `OrcaIntensityState v0`：availability、session/model identity、current-model `availableEfforts`、exact selected raw effort ID、adapter-provided `defaultEffortId` 与 ordinal `normalizedPosition`。
- `normalizedPosition = index / (count - 1)`，单档为 `0`；它仅表示 adapter-provided display order，不表示语义 reasoning strength。
- 规定 selected 与 future recommended 的分离；R2 不产生、持久化或自动应用 recommendation，且 v0 不包含 recommendation 字段。
- 验证 rc.6 当前模型的 `reasoning.efforts` 到原始 effort ID / ordinal presentation position 的 adapter 边界与空值行为。
- 明确 Intensity 的 session/active-session selector 与 Metrics/Activity 的独立性；保留 MetricsAdapter、ActivityAdapter 与 Token Monitor MVP 的现有 contract，不扩建 telemetry。
- 写明由当前 pinned DSH 到未来升级的 compatibility smoke，而不是在本阶段升级 DSH。

### Out of Scope

- dsh-market、dsh-context、dsh-pet 或任何默认/optional community bundle。
- Router、history、费用、动画 framework、Pet renderer、wallpaper engine、角色正式素材和 auto apply。
- DSH upgrade、installer/profile migration 改造或 public release。

### Entry Criteria

- Metrics / Activity 的 Orca runtime evidence 已足以维持现有 thin contracts；不把 deferred community plugin 作为 R2 dependency。
- Intensity consumer、portability 与 user-control requirements 经 review 明确。

### Exit Criteria

- Contract 小而稳定，未泄漏 Liang 0–30 刻度，不含 routing/recommendation policy。
- 普通 DSH plugin 可消费，不依赖 WinForms、dsh-market、dsh-context 或 dsh-pet。
- mapping、null、stale、selected/default 区分、selected/recommended 分离和 DSH upgrade smoke 语义有测试计划；preview 保持 renderer-local，source 不属于 v0。

### Artifacts

- Intensity contract specification and acceptance tests.
- Metrics/Activity adapter boundary confirmation.
- compatibility smoke additions and R3 renderer input contract.

R3 may consume `DshActivitySnapshot` and `OrcaIntensityStateV0` as required inputs. `DshMetricsSnapshot` is optional and only enters a presentation when that surface has a reviewed need for it.

## R3 — Orca Web Experience MVP

### Goal

用合法、可移植的素材和标准 DSH Web 插件形成首个真正差异化的 Orca experience。

### Scope

- Orca visual identity、角色和专属交互。
- 用 Orca ActivityAdapter 驱动 small Orca-owned Web presentation renderer；不采用或 fork `dsh-pet` 作为 Orca infrastructure。
- 兼容社区 Skin Center，不建立通用 skin framework。
- Activity 与 Intensity 驱动 Orca presentation；Metrics 仅在具体 presentation 有经 review 的必要性时引入。
- 首版 presentation renderer 只读；effort write/control、drag preview、recommendation 与 auto-apply 是独立 reviewed subphase，不随 R3 renderer MVP 自动进入。
- 在标准 `dsh web` 与 Orca reference host 中验证。

### Out of Scope

- Desktop Pet、Auto Routing、通用 Plugin Manager、历史 Analytics、Cost Database。

### Entry Criteria

- R2 contract 通过 review。
- 所有 Orca 素材权利清晰。
- 若引入任何额外社区组件，该精确组件通过准入 gate；R3 本身不依赖 R1 的三个 deferred candidate。

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
