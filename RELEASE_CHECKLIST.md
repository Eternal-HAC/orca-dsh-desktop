# OrcaDSH Release Regression Checklist

状态：R0 human-maintained checklist
更新日期：2026-08-20
Baseline HEAD：`37f4f59e57797c6739316f1e0ce13c7483b09818`

本文件把现有人工证据和正式 release 前仍需执行的回归项放在同一处。它不批准 release，也不替代 [ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md) 的版本 contract 或 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 的法律审计。

状态语义：

- `PASS`：当前 baseline 已有明确的人工或 adapter/runtime 证据；证据范围写在 Notes 中。
- `NOT VERIFIED`：没有足够明确、可追溯的当前证据，或只完成了代码审查。

任何候选 release 必须在实际候选 Setup 上重新执行完整清单；历史 PASS 不能自动继承到新 DSH、Node、WebView2、plugin 或 installer 组合。

## Current evidence snapshot

| Check | Status | Notes |
| --- | --- | --- |
| Clean per-user Setup install and desktop launch | PASS | 现有 desktop smoke；安装目录为 `%LOCALAPPDATA%\Programs\OrcaDSH`。 |
| Bundled Node is used | PASS | 实际 node 来自 Orca 安装/runtime 目录；固定版本 `24.14.0`。 |
| Isolated DSH_HOME is used | PASS | `%LOCALAPPDATA%\OrcaDSH`。 |
| Existing-profile Orca bundle upgrade | PASS | P0.9.1 incremental migration 后 Token Monitor 在真实 WebView 出现；只迁移 Orca-owned bundles。 |
| Credentials, sessions and config survive restart/reinstall and remain readable | NOT VERIFIED | 只有卸载后 DSH_HOME 目录保留的证据，没有逐项可读取性 smoke。 |
| New session starts with empty Orca projections | NOT VERIFIED | Adapter contract 已定义，缺少当前真实 WebView 的独立记录。 |
| Streaming estimate changes to provider exact usage | PASS | P0.7/P0.8 adapter/runtime evidence；尚未固化为候选 Setup 自动测试。 |
| Cache Read is displayed correctly | PASS | rc.6 provider usage / Token Monitor baseline evidence。 |
| Missing reasoning token remains `null` / `—` | PASS | rc.6 adapter and Token Monitor semantics 已验证，不伪造 reasoning token。 |
| Tool activity reaches `tool` and returns to review/done | PASS | P0.8 adapter/runtime evidence；候选 Setup 仍需重跑。 |
| Aborted activity reaches `failed` | PASS | P0.8 adapter/runtime evidence；候选 Setup 仍需重跑。 |
| Session A/B switching selects per-session projections | NOT VERIFIED | 没有当前真实 WebView 的可追溯人工记录。 |
| WebView refresh restores projection-backed Monitor state | NOT VERIFIED | 没有当前真实 WebView 的可追溯人工记录。 |
| Orca Token Monitor renders in real WebView | PASS | P0.9.1 E2E，可见 Input、Output、Reasoning、Cache Read、TPS、Status。 |
| Liang coexists with Token Monitor in development build | PASS | 仅说明 compatibility；不代表获得再分发许可。 |
| Explicit tray exit leaves zero Orca node/DSH processes | PASS | 人工 smoke 的 orphan process count = 0。 |
| Uninstall removes application directory | PASS | `%LOCALAPPDATA%\Programs\OrcaDSH` 已验证删除。 |
| Uninstall preserves DSH_HOME directory | PASS | `%LOCALAPPDATA%\OrcaDSH` 已验证保留；不等于重装后内容可读取性已验证。 |
| Direct license and NOTICE review is complete in final installed files | NOT VERIFIED | Liang BLOCKED；Node/WebView2 notice packaging 与 transitive npm audit 未完成。 |

## Candidate release execution record

每次候选 release 复制以下字段并填写，不要覆盖历史记录：

```text
Date:
Commit SHA:
Candidate version:
Setup path:
Setup SHA-256:
Windows version:
WebView2 runtime version:
DSH version:
Node version:
Fresh DSH_HOME path:
Existing DSH_HOME backup/reference:
Tester:
Result: PASS / FAIL / BLOCKED
Evidence paths:
Notes:
```

## Legal and publication gate

即使所有 runtime 项均为 PASS，出现以下任一情况仍禁止 public release：

- Liang 代码或媒体再分发权仍为 unresolved。
- 最终安装目录缺少许可证要求的 LICENSE/NOTICE 文本。
- 实际 bundled dependency tree 与 `THIRD_PARTY_NOTICES.md` 不一致。
- GitHub Actions 可以发布未经 gate 审核的候选产物。
- Setup、版本、SHA-256 或回归证据无法对应同一 commit。
