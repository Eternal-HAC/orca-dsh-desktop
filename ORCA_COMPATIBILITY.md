# OrcaDSH Compatibility Baseline

状态：Canonical, human-maintained  
更新时间：2026-08-20

本文件记录已经验证的精确组合和升级 seam。它不是对所有 DSH 或社区插件的兼容承诺。当前字段仍在 R0 阶段，不创建 `compatibility.yaml`。

## Runtime baseline

| Component | Version / Mode | Status |
| --- | --- | --- |
| DeepSeek Harness | `@deepseek-ai/dsh@0.1.0-rc.6` | Pinned, E2E PASS |
| Node.js | `24.14.0` Windows x64 private runtime | E2E PASS |
| WebView2 SDK assemblies | `1.0.4129.50` | Build PASS |
| WebView2 runtime | Evergreen system runtime assumed; app detects missing runtime and offers installation | Current machine PASS; exact runtime version not pinned |
| .NET | .NET Framework 4.8 WinForms host | Build/runtime PASS |
| Host | WinForms + WebView2, loopback `127.0.0.1:3080` | E2E PASS |
| Install mode | Per-user NSIS under `%LOCALAPPDATA%\Programs\OrcaDSH` | Install/uninstall PASS |
| User data | `%LOCALAPPDATA%\OrcaDSH` | Isolation PASS; uninstall preserves directory PASS; restart/reinstall readability not separately evidenced |

## Orca-owned plugins

| Package | Version | Role | Load mode | Status |
| --- | --- | --- | --- | --- |
| `orcadsh-state-adapters` | `0.1.0` | Host Metrics/Activity projections | Profile seed bundle | rc.6 spike and runtime E2E PASS |
| `dsh-client-orca-token-monitor` | `0.1.0` | Web current-session Monitor | Profile seed bundle | Real WebView E2E PASS |

Orca-owned plugin packages are copied into the profile seed at build time。最终用户首次启动不运行 npm、pnpm 或 git。

## Community plugins

| Package | Exact version | Default bundle | Compatibility | License / release status |
| --- | --- | --- | --- | --- |
| `dsh-client-liang-intensity-skin` | `0.1.4` release tarball | Yes, current baseline | rc.6 WebView coexistence and effort interaction PASS | Redistribution evidence incomplete; formal release BLOCKED |
| `dsh-market` | Not selected | No | Not tested | R1 candidate |
| `dsh-context` | Not selected | No | Not tested | R1 candidate |
| `dsh-pet` | Not selected | No | Not tested | R1 candidate; asset license must be audited |

未测试项目不得描述为兼容、默认 bundle 或 Orca 官方支持。

## Profile seed and migration

### Fresh install

- Setup 携带构建期生成的 `profile-seed`。
- 当 `%LOCALAPPDATA%\OrcaDSH\profiles\web` 不存在时复制干净 seed。
- Seed 包含 DSH base/web bundles、当前 Liang、Orca state adapters 和 Token Monitor。

### Existing profile

- P0.9.1 增量更新 `orcadsh-state-adapters` 和 `dsh-client-orca-token-monitor`。
- 只覆盖这两个 Orca-owned package 目录。
- 只在 `dsh.profile.bundles` 中追加缺失的 Orca bundle。
- 不覆盖 credentials、sessions、其他 bundles、其他插件或用户配置。

### Uninstall

- 删除安装目录和快捷方式。
- 默认保留 `%LOCALAPPDATA%\OrcaDSH`。

## E2E baseline

| Scenario | Status |
| --- | --- |
| Setup install and desktop launch | PASS |
| Bundled Node used | PASS |
| Independent DSH_HOME used | PASS |
| DSH backend and WebView2 load | PASS |
| Liang default display | PASS |
| Reasoning effort control | PASS |
| Real API request | PASS |
| Token Monitor visible in real WebView | PASS |
| Provider usage replaces estimate | PASS in adapter/runtime validation |
| Cache Read display | PASS |
| Reasoning token absent remains `null` / `—` | PASS |
| Liang and Token Monitor coexist | PASS |
| Explicit exit leaves zero Orca node/DSH processes | PASS |
| New session starts with empty Orca projections | PASS in isolated DSH_HOME runtime |
| Session A/B selects per-session projections | PASS in isolated DSH_HOME runtime |
| Standard web-client refresh restores projection-backed Monitor | PASS in isolated `dsh web`; WinForms WebView2-specific refresh not rerun |
| Same isolated DSH_HOME survives DSH host restart | PASS; session, metrics and activity remained readable |
| Full WinForms/Setup restart or reinstall retains credentials, sessions and configuration | NOT TESTABLE without touching real `%LOCALAPPDATA%\OrcaDSH` or adding a test seam |
| Uninstall removes app and preserves DSH_HOME | PASS |

`RELEASE_CHECKLIST.md` 记录 AUTOMATED、MANUAL/E2E 和 RELEASE-ONLY 的职责边界。历史 PASS 仍需在每个候选 Setup 上重跑。

## Public release policy

- `release-policy.json` 是 public release approval 的 repository-controlled state。
- `.github/workflows/release.yml` 的 tag 与 `workflow_dispatch` 共用 `scripts/Test-ReleasePolicy.ps1 -RequirePublicReleaseApproval`。
- 当前 `publicReleaseApproved` 为 `false`；workflow 可完成 build/package，但在 GitHub Release upload 前失败。
- 未来只能通过 reviewed repository change 关闭 blocker；CI secret 或临时 workflow input 不能覆盖 policy。

## Known rc.6 compatibility seams

### Host projection registration

```text
sessionProjections
```

`orcadsh-state-adapters` 通过该 Host service 注册 `orcaDshMetrics` 和 `orcaDshActivity`。升级时必须验证 service 名称、register contract、projection schema、stateVersion、event replay 和 `session.history/session.list` 输出。

### Web session projection access

```text
sessions.binding(sessionId)?.session.projections
```

Token Monitor 在 rc.6 通过该路径取得 per-session projection。升级时必须验证 `sessions` service、binding 形状、session identity、`faceOf()` 和 observable subscribe/getSnapshot contract。

### Client slot contract

```text
conversation.input.left
```

升级时必须验证 slot 名称、session scope、`slots.inject()` / `slots.register()` 参数、inject 接收的 sessionId，以及 client package 的 `./client` export 和 module loader factory contract。

### SessionEvent and usage

重点字段：

- `turn/start`、`turn/end`。
- `step/start`。
- `assistant/chunk` reasoning/text/usage。
- `assistant/message.data.usage` 与 rc.6 实际 provider usage 路径。
- `tool/call`、`tool/result`、aborted/error reason。
- cache read/write token 与独立 reasoning token 的可用性。

## DSH upgrade smoke gate

任何 DSH 升级至少需要：

1. Fresh temporary DSH_HOME profile boot。
2. Existing profile Orca bundle migration。
3. Host projection registration and replay。
4. New session empty state。
5. Streaming estimate → provider exact。
6. Reasoning、tool、completed、aborted activity sequence。
7. Session A/B switching and WebView refresh recovery。
8. Client slot rendering and Liang/community coexistence。
9. Real API request。
10. Explicit exit zero orphan process。
11. Restart/reinstall credentials and session readability；uninstall app removal and DSH_HOME retention。
12. License/NOTICE diff for every changed bundled component。

## License status convention

- `PASS`：代码、资产和 notice 证据足够进入目标发行方式。
- `BLOCKED`：缺少关键授权或 attribution，不能发行。
- `REVIEW`：材料存在但尚未完成具体版本审计。
- `N/A`：未 bundle，仅记录接口思想且未复制代码或资产。

当前 Liang 为 `BLOCKED`。Orca-owned package 使用本仓库 MIT，但未来若复制第三方 substantial code，必须在 notices 中单独记录来源和许可。

## Direct artifact evidence snapshot

当前 `dist/DeepSeekHarness` 中：

- DSH 自身 package 目录携带 `@deepseek-ai/dsh/LICENSE`。
- `licenses/Node-LICENSE.txt` 与固定 Node archive 的官方 LICENSE SHA-256 完全一致。
- `licenses/WebView2-LICENSE.txt`、`licenses/WebView2-NOTICE.txt` 与固定 WebView2 NuGet extract 完全一致。
- `licenses/OrcaDSH-LICENSE.txt` 与 repository root LICENSE 完全一致。
- app root `THIRD_PARTY_NOTICES.md` 与 repository source 完全一致，并记录 upstream desktop attribution。
- Liang package 没有 LICENSE/NOTICE，redistribution status 继续为 `BLOCKED`。

R0.4 development staging 与 ZIP 内容检查 PASS，NSIS Setup 构建 PASS。Setup installed tree 尚未在隔离 Windows 用户/机器执行，因此为 `NOT VERIFIED`。这只是直接关键组件证据，不代表 transitive npm dependency tree 已完成审计或完整法律合规。
