# OrcaDSH Decision Log

状态：Canonical  
更新日期：2026-08-20

本文件记录长期有效的产品和技术决策。历史调研提供证据，实际执行以本文件、[ARCHITECTURE.md](ARCHITECTURE.md) 和 [BUILD_REUSE_POLICY.md](BUILD_REUSE_POLICY.md) 为准。

## 2026-08-20 — Upstream DSH 保持原样

**Decision**  
Orca 不 fork、不 patch DSH core；功能通过官方 plugin、profile、bundle、service、projection 和 client slot 扩展。

**Reason**  
DSH 是 session、model、provider、settings 和持久化语义的权威来源。复制核心会形成第二套不兼容语义。

**Status**  
Accepted。

**Consequences**  
Orca adapter 必须明确版本边界；上游缺口优先通过插件或上游贡献解决。

## 2026-08-20 — Pin and deliberately upgrade DSH

**Decision**  
固定一个经验证的 DSH 版本并显式升级，不支持所有历史 rc。

**Reason**  
DSH 仍处于快速演化阶段，维护无限 fallback 会让兼容层失控。

**Status**  
Accepted；当前 pin 为 `0.1.0-rc.6`。

**Consequences**  
每次升级必须更新兼容矩阵并重跑 host、projection、client slot、profile migration 和数据保留 E2E。

## 2026-08-20 — Profile migration 只管理 Orca-owned bundles

**Decision**  
Orca migration 只安装或升级 Orca 自有 bundle，不成为通用 package manager。

**Reason**  
用户插件与配置属于用户；通用插件管理应由 DSH 或社区市场承担。

**Status**  
Accepted，P0.9.1 已实现。

**Consequences**  
迁移必须保留 credentials、sessions、其他 bundles 和用户配置；新增 Orca bundle 必须显式加入 allowlist。

## 2026-08-20 — 通用生态能力优先复用

**Decision**  
不自研 generic plugin manager、generic settings framework、Context Dashboard、generic Skin/Theme/Wallpaper framework 或 generic Web Pet engine。

**Reason**  
这些属于社区公共能力，重复实现缺乏 Orca 差异化并扩大维护面。

**Status**  
Accepted。

**Consequences**  
相关需求必须先通过第三方准入 gate；只有复用失败且 Orca 差异明确时才允许提出受限 Fork。

## 2026-08-20 — Token Monitor 停在 MVP

**Decision**  
保留当前会话 Token / TPS / Activity Monitor，不扩建历史统计、图表、费用数据库或通用 telemetry framework。

**Reason**  
MVP 已满足当前 session 可见性；更大 telemetry 平台与社区能力重叠，且会引入持久化和迁移成本。

**Status**  
Accepted。

**Consequences**  
后续工作限于 bug fix、DSH 兼容和 projection 正确性；新 analytics 需要新的产品证据和决策。

## 2026-08-20 — Metrics contract 保留，mapping 缩薄

**Decision**  
保留 `DshMetricsSnapshot` consumer contract，未来优先让底层适配可靠的官方或社区 projection。

**Reason**  
统一字段对 Orca UI 有价值，但 token 计算规则不是 Orca 应长期拥有的业务资产。

**Status**  
Accepted；当前 rc.6 event reducer 暂时保留。

**Consequences**  
不得扩建第二套 telemetry；替换 mapping 时必须保持 null、estimated 和 provider usage 语义。

## 2026-08-20 — Activity vocabulary 长期稳定

**Decision**  
保留 `idle | waiting | thinking | tool | review | done | failed`，底层事件 mapping 可以替换。

**Reason**  
这组状态适合 Pet、Skin、Wallpaper 和状态 UI 等 presentation consumer，同时不要求它们理解 DSH SessionEvent。

**Status**  
Accepted。

**Consequences**  
Activity 是 Orca facade，不是 universal agent runtime；第三方插件不必消费它。

## 2026-08-20 — IntensityState 独立于 Liang

**Decision**  
Orca Intensity 使用当前 adapter-provided ordered effort array 的 `normalizedPosition`（`index / (count - 1)`，单档为 `0`），并保留原始 `effortId`；该 position 不表示语义 reasoning strength，Liang 0–30 不是核心 contract。

**Reason**  
0–30 是特定皮肤的视觉隐喻。R2.1 rc.6 审计进一步确认 upstream 只承诺 adapter-preferred display order，未提供 numeric intensity、推荐值或视觉刻度。

**Status**  
Accepted and implemented in R2.2 as a client-side pure mapper/selector.

**Consequences**  
任何 Liang 兼容逻辑都位于 adapter 或 renderer 边界，不能泄漏为 Orca 公共状态刻度。

## 2026-08-20 — Selected 与 recommended intensity 分离

**Decision**  
用户当前选择与系统推荐必须是独立状态；推荐不得隐式覆盖用户 effort。

**Reason**  
任务路由、persona 和 reasoning effort 是不同语义，自动映射缺少稳定实验依据。

**Status**  
Accepted as architecture；尚未实现。

**Consequences**  
未来推荐只能先作为 UI suggestion；自动应用需要独立 benchmark、用户控制和新决策。

## 2026-08-20 — Auto Routing 当前跳过

**Decision**  
当前不开发、不默认集成 Auto Routing，也不集成 runtime injector。

**Reason**  
现有 routing 项目仍实验性，主要控制 persona/tool surface，而非 Orca presentation intensity；loader injector 兼容和许可风险均高。

**Status**  
SKIP。

**Consequences**  
R0–R4 均不以 routing 为交付条件。未来重新评估必须先 benchmark，并从 recommendation 开始。

## 2026-08-20 — Liang 是 redistribution/release blocker

**Decision**  
在代码许可和人物素材再分发授权明确，或素材被合法替换/移除之前，不把当前 Liang bundle 视为可正式公开发行内容。

**Reason**  
当前打包 package 没有 LICENSE/NOTICE，package metadata 没有 license 字段，并包含 24 张人物图；仓库无法证明完整授权链。

**Status**  
Blocked pending evidence or replacement。

**Consequences**  
正式 release 必须停止；`THIRD_PARTY_NOTICES.md` 和构建默认项将在 R0.2/R0 legal hygiene 中处理。此结论不等同于认定侵权，也不否认可能存在仓库外授权。

## 2026-08-23 — R1 社区候选不进入 Orca infrastructure

**Decision:**
`dshmarket`、`dsh-context` 和 `@linxin666/dsh-pet` 均保持 `DEFER`。三者均不 default bundle、不 optional bundle、不 Fork，也不作为 Orca infrastructure。Orca 不自研 generic Plugin Manager、Context Dashboard 或 generic Web Pet engine。

**Reason:**
三个 spike 都证明了社区生态的价值，也都暴露了当前 pinned DSH、profile distribution、licence/asset、trust、replay 或 host E2E 边界。没有一个候选同时达到 Orca default distribution 的 compatibility、offline、legal 和 zero-setup gate。

**Status:**
Accepted. `DEFER` is not `REJECT`; detailed re-evaluation gates are maintained in `BUILD_REUSE_POLICY.md`.

**Consequences:**
保留 MetricsAdapter、ActivityAdapter、Token Monitor MVP 和 thin Orca Compatibility Layer。未来 Orca Web Pet 如获单独批准，只能优先沿 `ActivityAdapter → small Orca-owned presentation renderer → Orca-owned licensed assets` 设计，而不采用 dsh-pet 作为基础设施。

## 2026-08-23 — R2 保持为独立于社区候选的 Intensity contract review

**Decision:**
R2 先审查并定义 user-controlled `OrcaIntensityState v0`，不以任何 R1 community candidate 或 DSH upgrade 为前提；v0 使用 per-ordinary-session、model-derived raw effort IDs 和 ordinal `normalizedPosition`，selected 与 future recommended 保持分离，R2 不实现 routing 或自动应用。

**Reason:**
当前 rc.6 已有 reasoning effort interaction 与 Orca Metrics/Activity runtime evidence。R2.1 确认 selected effort 来自 Host ModelSelection，available efforts/default 来自当前 ModelDirectory model metadata；先冻结不泄漏 Liang 0–30 的 presentation contract，可为合法 Orca renderer 和未来 DSH upgrade 建立最小输入边界，同时避免因 deferred community package 扩大 scope。

**Status:**
R2.1 contract reviewed; R2.2 implementation completed and reviewed.

**Consequences:**
v0 不包含 preview、source 或 recommendation 字段；preview 是 renderer-local transient state，recommendation 是未来独立状态/policy。R2 不安装社区插件、不升级 DSH、不改 installer，也不重构 profile migration；R2.2 仅沿用既有机制加入 Orca-owned bundle migration 条目。R2 不做 Pet renderer 或正式素材。R3 的任何 renderer 只能在 R2 contract 和素材授权通过后再提出。
