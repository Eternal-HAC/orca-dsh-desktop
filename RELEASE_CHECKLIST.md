# OrcaDSH Release Regression Checklist

状态：R0 human-maintained checklist
更新日期：2026-08-20
Baseline HEAD：`ec49b353b45c599dc63ce260cc2924530b381f86`

本文件定义 release regression 的最小职责边界。它不批准 release，也不替代 [ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md) 的版本 contract、[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 的法律审计或 `release-policy.json` 的 public-release approval state。

状态语义：

- `PASS`：当前 baseline 有真实且范围明确的执行证据。
- `FAIL`：实际执行未满足预期。
- `NOT VERIFIED`：尚未执行或证据不足。
- `NOT TESTABLE`：当前安全测试边界无法执行；必须记录具体限制。

任何候选 release 必须在实际候选 Setup 上重新执行适用清单；历史 PASS 不能自动继承到新 DSH、Node、WebView2、plugin 或 installer 组合。

## AUTOMATED

适合每次提交或 release workflow 执行的轻量、无 GUI 验证。

| Check | Status | Command / evidence |
| --- | --- | --- |
| PowerShell scripts parse | PASS | PowerShell AST：`build.ps1`、`package-release.ps1`、`scripts/Test-ReleasePolicy.ps1`、`scripts/Test-ReleaseBaseline.ps1`。 |
| Release policy structure | PASS | `scripts/Test-ReleasePolicy.ps1`；当前 policy 合法且为 BLOCKED。 |
| Blocked policy prevents upload approval | PASS | `-RequirePublicReleaseApproval` 按预期非零退出并显示 Liang blocker。 |
| Future approved policy shape is testable | PASS | `scripts/fixtures/release-policy-approved.json` 仅作为 repo test fixture，通过 validator；workflow 不引用它。 |
| Profile seed structure | PASS | `scripts/Test-ReleaseBaseline.ps1`。 |
| Bundled Node / DSH exact version | PASS | Node `24.14.0`；DSH `0.1.0-rc.6`。 |
| Orca-owned bundles present | PASS | state adapters 与 Token Monitor package、bundle 和 entry files。 |
| Required Liang development bundle present | PASS | `dsh-client-liang-intensity-skin@0.1.4`；只代表当前 development baseline，不代表 release approval。 |
| Seed excludes credentials, sessions and logs | PASS | 对 profile seed 的运行时数据文件/目录扫描。 |
| Release metadata has no likely API key/Bearer credential | PASS | 轻量 secret-pattern scan；不代替专用 secret scanner。 |
| GitHub Actions YAML parses | PASS | bundled Node + bundled `js-yaml`。 |
| Both public triggers share one upload gate | PASS | `v*` 与 `workflow_dispatch` 进入同一 job；gate 位于 `softprops/action-gh-release@v2` 前。 |
| Direct redistributed component evidence in staging | PASS | `Test-ReleaseBaseline.ps1` 验证 repository LICENSE、THIRD_PARTY_NOTICES、Node LICENSE、WebView2 LICENSE/NOTICE 和 DSH LICENSE 均存在且非空。它不是完整依赖许可证审计。 |
| Direct redistributed component evidence in ZIP | PASS | R0.4 `DeepSeekHarness-Desktop-v0.2.0-win-x64.zip` 条目检查包含全部上述文件。 |

## MANUAL / E2E

保留为人工 desktop/WebView 或隔离 runtime 验证；不引入 Playwright、WinAppDriver、Selenium 等项目依赖。

| Check | Status | Notes |
| --- | --- | --- |
| Clean per-user Setup install and desktop launch | PASS | 既有 desktop smoke；安装目录 `%LOCALAPPDATA%\Programs\OrcaDSH`。候选 Setup 仍需重跑。 |
| Bundled Node is used | PASS | 实际 node 来自 Orca 安装/runtime 目录；固定 `24.14.0`。 |
| Isolated DSH_HOME is used | PASS | 真实 desktop baseline 使用 `%LOCALAPPDATA%\OrcaDSH`。 |
| Existing-profile Orca bundle upgrade | PASS | P0.9.1 migration 后 Token Monitor 在真实 WebView 出现。 |
| Real WebView Token Monitor renders | PASS | P0.9.1 可见 Input、Output、Reasoning、Cache Read、TPS、Status。 |
| New session starts with empty Orca projections | PASS | R0.3 隔离 DSH_HOME runtime：Input/Output/Reasoning/Cache Read/TPS 均为 `—`，Status `Idle`；projection cache 对应字段为 null。 |
| Streaming estimate changes to provider exact usage | PASS | P0.7/P0.8 runtime evidence；候选 Setup 仍需重跑。 |
| Cache Read is displayed correctly | PASS | rc.6 provider usage / Token Monitor baseline evidence。 |
| Missing reasoning token remains `null` / `—` when provider omits it | PASS | rc.6 adapter/Monitor contract；不伪造 token。R0.3 隔离请求实际返回独立 reasoning usage，因此该次显示数字不改变 null 语义。 |
| Tool activity reaches `tool` and returns to review/done | PASS | P0.8 runtime evidence；候选 Setup 仍需重跑。 |
| Aborted activity reaches `failed` | PASS | P0.8 runtime evidence；R0.3 隔离 session A 中止后也显示 `Failed`。 |
| Session A/B switching selects per-session projections | PASS | R0.3 隔离 runtime：A 显示 781/913/434、Cache Read 9.1K、Failed；B 显示全空值、Idle；双向切换正确。数字只作为本次证据，不是固定预期。 |
| Client refresh restores projection-backed Monitor state | PASS | R0.3 标准 `dsh web` 刷新后 A/B 各自状态恢复；未执行 WinForms WebView2 专项刷新。 |
| Same isolated DSH_HOME survives DSH host restart | PASS | R0.3 停止并重启 bundled DSH host 后，session A 和 projection-backed Monitor 恢复。 |
| Liang coexists with Token Monitor in development build | PASS | 只说明 compatibility；不代表再分发许可。 |
| Explicit tray exit leaves zero Orca node/DSH processes | PASS | 既有人工 desktop smoke，orphan count = 0。 |

## RELEASE-ONLY

只能在明确标识的候选 Setup、受控测试用户/机器与最终 installed tree 上完成。

| Check | Status | Notes |
| --- | --- | --- |
| Restart/reinstall retains readable credentials, sessions and config | NOT TESTABLE | App 固定从 `.NET Environment.GetFolderPath(LocalApplicationData)` 使用真实 `%LOCALAPPDATA%\OrcaDSH`；进程环境变量不能安全重定向。本轮禁止读取/覆盖真实用户数据，也未增加 runtime test seam。隔离 DSH host restart PASS 只覆盖部分语义。 |
| Uninstall removes application directory | PASS | 既有候选 Setup smoke：`%LOCALAPPDATA%\Programs\OrcaDSH` 删除。新候选仍需重跑。 |
| Uninstall preserves DSH_HOME directory | PASS | 既有 smoke：`%LOCALAPPDATA%\OrcaDSH` 保留；不等于重装后逐项可读。 |
| NSIS Setup contains current staging payload | PASS | R0.4 `build.ps1` 完整执行且 `File /r` 编译成功；生成 validation-only Setup。 |
| Final installed-file license / NOTICE audit | NOT VERIFIED | 未静默安装：当前 installer 会写真实桌面/开始菜单快捷方式和 HKCU uninstall key，本机没有安全的完全隔离安装目标。需在隔离测试用户/机器检查 installed tree。 |
| Public release blocker status | BLOCKED | `release-policy.json`：`Liang redistribution rights unresolved`。 |
| Setup/version/SHA/evidence all map to one commit | NOT VERIFIED | 尚无 R0.3 release candidate；本轮禁止打包/public release。 |

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

即使全部 runtime 项为 PASS，出现以下任一情况仍禁止 public release：

- `release-policy.json` 未明确批准 public release，或仍列有 blocker。
- Liang 代码或媒体再分发权 unresolved。
- 最终安装目录缺少许可证要求的 LICENSE/NOTICE 文本。
- 实际 bundled dependency tree 与 `THIRD_PARTY_NOTICES.md` 不一致。
- Setup、版本、SHA-256 或回归证据无法对应同一 commit。

关闭 Liang blocker 必须通过 reviewed repository change，依据只能是明确授权、从 public artifact 移除 Liang，或以权利清晰的 Orca 自有内容替换。不得用 CI secret、workflow input 或临时脚本绕过。
