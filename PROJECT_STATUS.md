# OrcaDSH Project Status

状态：Canonical  
更新时间：2026-08-20

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

Public release remains `BLOCKED`。R1.1 `dsh-market` isolated integration spike 已完成，结论为 `DEFER`；未默认 bundle，未开始 `dsh-context`、`dsh-pet` 或其他功能实现。

## Git baseline

```text
branch: main
closure starting HEAD: ec49b353b45c599dc63ce260cc2924530b381f86
closure starting origin/main: 37f4f59e57797c6739316f1e0ce13c7483b09818
R0 closure baseline: this document's containing commit
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

R0.3 working tree 新增 repository-controlled `release-policy.json` 和共用 gate。`v*` tag 与手动 workflow 均在上传前执行同一个 approval check；当前 policy 默认为 blocked，原因是 Liang redistribution rights unresolved。该修改尚未 commit/push，因此远端 workflow 仍未获得保护。

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

## 未验证

- `dsh-context`、`dsh-pet` 与 Orca rc.6 的真实兼容性。
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

R0 已关闭。R1.1 已完成并停止。Next Approved Work：**R1.2 `dsh-context` isolated integration spike**。本次 closure 不启动 R1.2；不得自行开始 R1.3 `dsh-pet`、默认 bundle、runtime/toolchain 修改、installer 修改、DSH core 修改、tag 或 public release。
