# OrcaDSH Project Status

状态：Canonical  
更新时间：2026-08-23

## 当前阶段

```text
P0.9.1: Complete
R0.1 / R0.1.1: Review complete
R0.2: Review complete
R0.3: Review complete
R0.4: Review complete
R0: Complete
Next phase: R1 Community Integration Spikes
```

Public release remains `BLOCKED`。R1.1 `dsh-market`、R1.2 `dsh-context` 与 R1.3 `@linxin666/dsh-pet` isolated integration spike 已完成，结论均为 `DEFER`；没有默认 bundle、optional bundle 或 Fork。

## Git baseline

```text
branch: main
current reviewed HEAD: 6bfa619e4aa43f784fa2413c8759b785c03f9b42
origin/main: 6bfa619e4aa43f784fa2413c8759b785c03f9b42
historical R0 closure starting HEAD: ec49b353b45c599dc63ce260cc2924530b381f86
historical R0 closure starting origin/main: 37f4f59e57797c6739316f1e0ce13c7483b09818
```

`deep-research-report.md` 是未跟踪的研究输入，不是 canonical specification。

## 已实现

- C# WinForms + WebView2 Windows reference host。
- bundled Node.js `24.14.0`。
- `@deepseek-ai/dsh@0.1.0-rc.6`。
- 独立 `%LOCALAPPDATA%\OrcaDSH` DSH_HOME。
- 用户级 NSIS Setup、快捷方式和卸载。
- 托盘生命周期与显式真正退出的进程树清理。
- Liang Intensity Skin `0.1.4` 当前默认 seed 集成。
- `orcadsh-state-adapters` Metrics / Activity projections。
- `dsh-client-orca-token-monitor` 当前 session MVP。
- existing-profile Orca-owned bundle incremental migration。

## 已验证

| 验证项 | 结果 | 证据范围 |
| --- | --- | --- |
| Windows desktop build | PASS | 当前机器完整 build 成功。 |
| bundled Node isolation | PASS | 实际 node 来自 Orca 安装/runtime 目录。 |
| isolated DSH_HOME | PASS | `%LOCALAPPDATA%\OrcaDSH`。 |
| DSH backend / WebView2 | PASS | 真实 desktop smoke。 |
| Liang default load | PASS | 真实 WebView 可见。 |
| Reasoning effort interaction | PASS | 原始 effort 选择可用。 |
| Real API conversation | PASS | 已发送真实请求。 |
| Token Monitor WebView E2E | PASS | 可见 Input、Output、Reasoning、Cache Read、TPS、Status。 |
| Liang / Token Monitor coexistence | PASS | 同一 WebView 同时显示。 |
| Explicit exit cleanup | PASS | orphan Orca node/DSH process count = 0。 |
| Uninstall install-dir removal | PASS | `%LOCALAPPDATA%\Programs\OrcaDSH` 删除。 |
| Uninstall user data retention | PASS | `%LOCALAPPDATA%\OrcaDSH` 保留。 |
| New-session empty Orca projections | PASS | 隔离 DSH_HOME runtime；Monitor 全部为空值并显示 Idle。 |
| Session A/B projection switching | PASS | 隔离 DSH_HOME runtime；A 的 metrics/Failed 与 B 的空值/Idle 双向切换。 |
| Web client refresh projection restore | PASS | 隔离 `dsh web` 客户端刷新后恢复 A/B 对应 projection；未宣称为 WinForms WebView2 专项 E2E。 |
| Isolated DSH host restart retention | PASS | 同一隔离 DSH_HOME 重启 host 后，session、metrics、activity 可重新读取。 |

## 当前 release blockers

### Liang redistribution evidence

当前 bundle 中 Liang package 没有 LICENSE/NOTICE，metadata 没有 license 字段，并包含 24 张人物图。仓库无法证明完整代码与素材授权链。获得明确授权或替换/移除相关内容之前，不批准正式公开 release。

### Release hygiene

R0.4 build 已将当前有明确来源的 direct redistribution evidence 纳入 staging：`licenses/OrcaDSH-LICENSE.txt`、`Node-LICENSE.txt`、`WebView2-LICENSE.txt`、`WebView2-NOTICE.txt`，以及 app root 的 `THIRD_PARTY_NOTICES.md`。DSH LICENSE 继续位于 package tree。Development staging 与 ZIP 已验证 PASS，NSIS Setup 构建 PASS；installed tree 尚未在隔离 Windows 用户/机器实际验证。transitive npm dependency 审计仍未完成。

R0.3 已将 repository-controlled `release-policy.json` 和共用 gate 提交并推送至 `origin/main`（`6588b449c8fb960e8c49fea57e1169baecbdcc92`）。`v*` tag 与手动 workflow 均在上传前执行同一个 approval check；当前 `publicReleaseApproved=false`，原因是 Liang redistribution rights unresolved。现有 policy/workflow validation 已通过，但这不代表已执行或通过真实 public release 测试。

Installer、exe、namespace、mutex、artifact path 和默认 `0.2.0` build/version 常量等仍保留 pre-Orca legacy identifier。为避免扩大本轮到 runtime/installer identity migration，R0.2 只记录这些 seam，没有机械重命名。

### Regression formalization

已将 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) 分为 AUTOMATED、MANUAL/E2E、RELEASE-ONLY，并新增轻量 baseline/policy scripts。隔离 runtime 已验证 new-session、session A/B、client refresh 和 DSH host restart。完整 WinForms/Setup 重装后的 credentials、sessions、config 可读取性仍是 `NOT TESTABLE`：当前 App 固定使用真实 `%LOCALAPPDATA%\OrcaDSH`，环境变量不能安全重定向 `.NET Environment.GetFolderPath(LocalApplicationData)`，本轮禁止触碰真实用户数据或改 runtime test seam。

## R1.1 spike result

- 精确基线：`dshmarket@1.16.0`，commit `fa5200829cbcc2a0cb4b5e0d2199f74a26f928fc`。
- 普通 DSH rc.6：Host routes、Settings Market UI、catalog、刷新、fixture install/enable/disable/restart/remove 均在隔离 DSH_HOME PASS。
- Orca-owned bundle：隔离 lifecycle 后 bundle 行与 package 目录保留；真实 WinForms/WebView2 reference host 因固定真实 LocalAppData DSH_HOME 而 `NOT TESTABLE SAFELY`。
- 分发 seam：Market 自身可预打包，但插件管理需要 pnpm。当前 Orca private Node 不含 pnpm/npm/corepack；仅 bundled-runtime PATH 下 `pnpm: false`，自动准备失败。
- 维护 seam：上游 `v1.16.0` tag 的 `package.json` 与 lockfile 不一致，允许重锁后 source build 又缺少 `@deepseek-ai/schemastery`。
- 决策：`DEFER`；不 default bundle、不 optional bundle、不 Fork。完整证据见 `research/R1_DSH_MARKET_SPIKE.md`。

## R1.2 spike result

- 精确基线：`dsh-context@0.19.1`，commit `aa768c76a1d875a413c13a213262c74f0187930f`。
- 普通 DSH rc.6：Host/Client、`contextTimeline` / `contextHeaders`、Context tab 与 `/context`、两轮 provider 响应、reasoning、tool、abort、A/B、refresh、host restart 均 PASS；real compaction/prune 未测试。
- 数值对照：启发式当前构成 `12,051` 等于官方 `contextBreakdown` 三项之和；最近一步实际 prompt `12,331` 等于 Orca exact input `171` + cache read `12,160`；provider-anchored occupancy `12,703` 与官方 `contextPressure.projectedTokens` 一致。
- 共存：Liang effort slider、Orca Token Monitor 与 state projections 同时工作，无 key/slot/reducer collision。
- 分发 seam：上游硬 peer 指向 rc.8；标准 add 将复制 seed 从 48 files / 43.98 MiB 重整为 1,047 files / 93.66 MiB，并重装/重链 Liang。完整 seed 可做到用户侧无需 npm/pnpm/git，但当前未设计 migration。
- 隐私 seam：完整 prompt/reasoning/tool/system 内容只走本地 projection；未发现 telemetry/session upload。插件信息卡每小时最多访问一次 npm registry 查询最新版，不发送 session 内容。
- 决策：`DEFER`；不 default bundle、不 optional bundle、不 Fork；同时停止自研通用 Orca Context Dashboard。完整证据见 `research/R1_DSH_CONTEXT_SPIKE.md`。

## R1.3 spike result

- 精确基线：`@linxin666/dsh-pet@0.2.9`，GitHub `v0.2.9` tagged commit `117b0001b6c91d13245d0f239f0b7f33dadd95fa`。
- DSH version-range seam：upstream declared `dsh.engines.dsh = >=0.1.1-rc.1`，而 Orca 为 `0.1.0-rc.6`，故为 `OUTSIDE DECLARED RANGE`。普通 rc.6 Host/Client、loopback asset route、内置 WebP sprite、display toggle、position/size persistence、refresh 和 host restart boot 的 PASS 仅覆盖 exercised paths 的经验兼容，不代表 upstream supports rc.6。Test host state reset idle on restart by design.
- 架构 seam：没有 `sessionProjections`；插件直接监听 `session/event`，在 host memory 维护 per-session bubbles 和 global visible state。它会重复 Orca ActivityAdapter 的 reducer，不能作为 Orca Activity source。
- Settings/client seam：宠物设置表单报告配置 namespace 未暴露，标记为 compatibility shim required；它独立于 DSH version-range mismatch。
- 资产/隐私 seam：direct code Apache-2.0 evidence exists, but character sprites/previews lack independently auditable redistribution evidence; package also reads session text/reasoning/tool payload for whisper/interaction presentation. No normal-path telemetry or remote asset fetch was found.
- 决策：`DEFER`；不 default bundle、不 optional bundle、不 Fork、不 build Orca generic Web Pet engine。完整证据见 `research/R1_DSH_PET_SPIKE.md`。

## 未验证

- `@linxin666/dsh-pet` 的真实 provider reasoning/tool/completed/aborted/error lifecycle、Session A/B、event replay，以及 safely isolated WinForms/WebView2 E2E；当前 package 不提供 DSH projection replay。
- `dsh-context` 的 safely isolated WinForms/WebView2 E2E、真实 compaction/prune、长期会话性能、稳定 peer range 和 transitive license。
- `dshmarket` 的 WinForms/WebView2 reference-host 隔离 E2E、Orca-private pnpm 方案、transitive license 和后续稳定 release。
- WinForms/Setup 重启或重装后 credentials、sessions 和配置仍可读取的逐项隔离 smoke；当前只有隔离 DSH host restart 与卸载后真实 DSH_HOME 目录保留证据。
- OrcaIntensityState 的 contract 和 portability。
- 未来 DSH 版本升级。
- Liang 是否存在仓库外授权。
- 研究报告中的动态 stars、plugin 数量和其他时间敏感生态数据。
- R0.4 Setup 安装后的实际 license/NOTICE tree；当前 installer 会写真实快捷方式和 HKCU uninstall key，不能在本机无副作用隔离。

## R0 closure and release classification

- **R0 governance — COMPLETE**：canonical product/architecture/decision documents、Build/Reuse policy、compatibility baseline、release checklist、README/CHANGELOG/NOTICE hygiene、release gate、direct redistribution evidence baseline 和 regression classification 已完成 review。
- **Public release blocker**：Liang redistribution rights unresolved；实际 bundled transitive dependency tree 的法律审计仍未完成。
- **Release-candidate-only verification — DEFER TO R4**：候选 Setup 的 installed-tree LICENSE/NOTICE、restart/reinstall credentials/session/config readability，以及 Setup SHA/version/commit/evidence 对应。

Open public-release 和 release-candidate-only 项不阻止 R1 isolated community integration spikes，但继续阻止任何 public OrcaDSH release。

## Next Approved Work

R1.3 complete. **Next: R1 closure review.** R1.1、R1.2 与 R1.3 的 community integration spike 均为 `DEFER`，没有 approved default-bundle candidate。Any R2 scope requires a new reviewed decision;不得自行默认 bundle、修改 runtime/toolchain、installer、DSH core、tag 或 public release。
