# R1.2 dsh-context Isolated Integration Spike

状态：Completed spike, decision `DEFER`

日期：2026-08-20

范围：隔离测试；未修改 Orca production profile、migration、runtime 或 installer

## Exact Baseline

| Item | Exact value |
| --- | --- |
| Repository | `https://github.com/bowenliang123/dsh-context` |
| Package | `dsh-context` |
| Release | `v0.19.1`, stable GitHub release |
| Commit | `aa768c76a1d875a413c13a213262c74f0187930f` |
| Release time | `2026-08-20T14:46:14Z` |
| npm publish time | `2026-08-20T14:47:29.836Z` |
| npm tarball SHA-1 | `b5c0136bf76140fca6db9eaa190ae8b2314e80e9` |
| npm integrity | `sha512-QcSpbLXPL1WOsfFRlHTqAy4kYT/IKpoeJObwFt2bdmqy9mWdviif83poWdOeuZGXuiOMVcpXkLd/1HCv08Xomg==` |
| Node | Orca bundled `v24.14.0` |
| DSH | Orca pinned `0.1.0-rc.6` |
| Test DSH_HOME | `%TEMP%\orcadsh-r12-context-home-8c7f676432a04d3c9d392f3b4146d420` |
| Profile origin | Copy of current Orca `profile-seed/profiles/web`; no credentials or sessions copied |

The repository was created on 2026-08-14 and published versions `0.1.0` through `0.19.1` within six days. During this spike the UI already reported `0.19.2` as available. This is concrete maturity and upgrade-cadence risk, not evidence that the project is unsafe.

## License

- Repository root `LICENSE` is the Apache License 2.0 with an Appendix copyright notice for 2025 bowenliang123.
- `package.json.license` is `Apache-2.0`.
- The published `dsh-context-0.19.1.tgz` contains the same full `LICENSE`, compiled Host and Client files, README and Cordis patch. npm `gitHead` matches the audited tag commit and the downloaded tarball hashes match npm metadata.
- No `NOTICE` file is present in the repository or published package. No bundled third-party code or GPL/AGPL/copyleft text was found in the direct six-file package.
- Repository screenshots/social-preview assets have no separate asset-license evidence. They are excluded by the npm `files` allow-list and are not in the tested package; they would need a separate audit if Orca copied them.
- The direct runtime dependency is `zod@^4.4.3`; Cordis, DSH session, React and client primitives are peers. This spike did not complete the transitive dependency license audit.

Conclusion: direct-package Apache-2.0 evidence is sufficient for isolated evaluation. It is not a complete legal-clearance statement for a future Orca bundle.

## Architecture

`dsh-context` is a combined ordinary DSH Host and Web Client plugin. It has no WinForms, WebView2, Electron or desktop-only dependency.

Host side:

- `cordis.patch.yml` inserts one `dsh-context` Cordis loader row.
- `src/host/index.ts` hard-injects `sessionProjections` and registers `contextTimeline` plus `contextHeaders`.
- The framework drives both pure projection folds from committed `session/event` records and persists their bounded state through DSH's projection cache.
- There is no custom RPC route, global accumulator or plugin-owned database.

Web client side:

- `src/client/index.ts` registers a `conversation.view` tab and a `/context` modal in `conversation.input.overlay`.
- Components read per-session values through standard `useProjection(...)` props. They do not parse the DOM and do not recalculate SessionEvent history in the renderer.
- The client optionally contributes `loadOlderHistory` through `sessions.provide` for browser pagination.

The current manifest declares a hard peer on `@deepseek-ai/dsh-session@^0.1.0-rc.8`, even though the exact package booted and worked on Orca rc.6. The peer declaration therefore does not promise rc.6 support; Orca's result is a tested compatibility exception that must be rechecked on every upgrade.

## Context Semantics

The plugin's primary product is context composition and lifecycle inspection, not general usage telemetry.

| Display concept | Meaning | Source |
| --- | --- | --- |
| Current composition | Estimated model-visible next-request surface split into system, tool schemas, user, injected, assistant and tool-result categories | `contextTimeline` fold; fixed-density heuristic |
| Current headline | Best-known next-request occupancy | Official `contextPressure.projectedTokens`, then provider-anchored fallback, then heuristic total |
| Context window | Routed model capacity | `request/context.contextWindow`; exposed by official `contextPressure` when available |
| Request prompt | Provider prompt-side tokens for one request: uncached input + cache read + cache write | `assistant/message.data.usage` |
| Request output | Provider-reported output for one request; reasoning is already included | `assistant/message.data.usage.outputTokens` |
| Cache hit | Cumulative `cacheRead / (uncachedInput + cacheRead + cacheWrite)` | Official `tokenUsage` projection |
| History | One record per completed model request/step, optionally aggregated by turn | `contextTimeline.requests` |
| Compaction/prune/injection/model switch | Durable context-changing events | SessionEvent fold |
| Remaining / percentage | Context window minus the best-known occupancy | Derived in client; unknown when capacity is absent |

Heuristic pricing is explicit: about four characters per token plus content-block and role overhead. It estimates system prompt, tool definitions, user/assistant text, reasoning blocks, tool-call arguments and tool results. It does not claim tokenizer-exact category values.

Cache tokens are not added to composition as a separate category. They describe how the already-counted prompt was billed. Provider prompt is calculated once as `inputTokens + cacheReadTokens + cacheWriteTokens`, so cache is not double counted.

Assistant text and reasoning become part of the next request's assistant-message surface. Reasoning has no separate Context category and provider output already includes reasoning. The plugin does not expose TPS, independent reasoning usage or per-turn activity state.

## Data Sources

| Source | Use |
| --- | --- |
| `request/header` | System prompt, tool schemas, provider/model envelope and header epochs |
| `request/context` | Provider, model and `contextWindow` route metadata |
| `user/message` | Human and injected user-role surface nodes |
| `assistant/message` | Completed request snapshot, provider usage and assistant surface node |
| `tool/call`, `tool/result` | Tool identity and model-visible tool-result content |
| `compaction/summary`, `compaction/prune` | Removed-node archive and context lifecycle markers |
| Official `contextPressure` projection | Provider-anchored current occupancy and capacity |
| Official `tokenUsage` projection | Durable cumulative provider input/output/cache buckets |
| DSH session projection cache | Per-session restart/replay persistence |

The plugin does not call the model/provider itself, request extra provider usage, scrape the Web UI, read settings for token semantics or modify DSH session/profile persistence semantics.

## Installation / Profile Changes

Command used with the isolated DSH_HOME:

```text
<Orca bundled node.exe> <bundled @deepseek-ai/dsh/lib/bin.js> plugin --profile web add dsh-context@0.19.1
```

Observed changes:

- `profiles/web/package.json`: added dependency `dsh-context: 0.19.1` and appended bundle `dsh-context`.
- `profiles/web/pnpm-lock.yaml`: created/reconciled the complete profile dependency graph.
- `profiles/web/pnpm-workspace.yaml`: created and added a release-age exception for the exact package.
- `profiles/web/node_modules`: created `.pnpm`, `.modules.yaml`, package links and metadata.
- `dsh-context/lib/index.js`, `lib/client.js`, `LICENSE`, README and patch were installed.
- No plugin-owned storage or additional profile-state file appeared.

pnpm moved the pre-existing Liang directory to `node_modules/.ignored` because it came from a different package-manager layout, then downloaded and relinked Liang. Orca's two locally bundled packages remained present. The resulting profile grew from 48 files / 43.98 MiB to 1,047 files / 93.66 MiB; `dsh-context` itself is only about 0.16 MiB. Most growth came from pnpm metadata and the rc.8 peer dependency graph.

Build-time integration can pin and preinstall the package into a future profile seed. If that seed is complete and migration is designed, final users need no npm, pnpm, git, native module, additional service or online install at first launch. Directly asking existing users to run the tested add command would require a working pnpm path and would rewrite their profile dependency graph; Orca does not support that as a zero-setup route.

## Overlap With Orca Metrics

| Concern | dsh-context | Orca MetricsAdapter / Token Monitor |
| --- | --- | --- |
| Current context occupancy | Official `contextPressure` plus composition fallback | Not exposed as a context-window product |
| Context category composition | Yes, heuristic and event-derived | No |
| Per-request provider prompt/output | Yes, in history | Current/latest session metrics only |
| Cumulative cache hit | Yes, official `tokenUsage` | Latest snapshot shows cache-read bucket |
| Input/output/cache snapshot | Partial overlap | Stable Orca snapshot contract and compact UI |
| Reasoning tokens | Included in output; no independent field | Independent when provider reports it, otherwise `null` |
| TPS | No | Yes |
| Activity | No | Orca ActivityAdapter |

`dsh-context` is more authoritative for context occupancy because it directly consumes DSH's official context projections and maintains composition history. Orca remains more suitable for current-call TPS, independent reasoning usage and normalized activity.

MetricsAdapter should not consume `contextTimeline`; doing so would couple a thin Orca telemetry facade to an optional community UI package and mix different semantics. Orca should let `dsh-context` own generic Context UI if it is adopted later. There is no evidence supporting an Orca Context Dashboard or Context-specific adapter now.

## Compatibility Matrix

| Seam | Result | Evidence |
| --- | --- | --- |
| DSH Host loader | PASS | Exact package loaded through normal rc.6 profile bundle. |
| `sessionProjections` | PASS | `contextTimeline` and `contextHeaders` present in real `session.list` values. |
| SessionEvent shape | PASS for exercised paths | request header/context, user, assistant, reasoning, tool call/result and aborted turn folded correctly. Compaction/prune not exercised in real E2E. |
| Model metadata | PASS | Provider/model and 1,000,000 context window matched `request/context`/official pressure projection. |
| Client loader / `./client` | PASS | `/context` candidate, modal and Context tab rendered without module errors. |
| Client exports | PASS | Published client bundle loaded under rc.6. |
| `conversation.view` slot | PASS | Context tab appeared next to Chat and Trajectory. |
| `conversation.input.overlay` | PASS | `/context` opened the modal in a new empty session. |
| Settings | N/A | Token/context semantics do not depend on a settings service. |
| Profile bundle | PASS WITH DISTRIBUTION RISK | Standard add succeeded, but reconciled the whole profile and pulled rc.8 peers. |
| Session A/B | PASS | Empty session showed zero context; populated session restored its own values after switching back. |
| Refresh replay | PASS | Selected Context tab and values restored after browser refresh. |
| Host restart | PASS | Same session projection values restored after stopping/restarting rc.6. |
| Orca WinForms reference host | NOT TESTABLE SAFELY | `App.cs` fixes DSH_HOME to `%LOCALAPPDATA%\OrcaDSH`; no runtime test seam was added. |

No Orca compatibility shim was needed in ordinary `dsh web`. The hard rc.8 peer declaration and whole-profile pnpm reconciliation remain compatibility/distribution seams, not reasons to create a semantic adapter.

## E2E Results

| Scenario | Result | Evidence |
| --- | --- | --- |
| Isolated profile boot | PASS | Bundled Node 24.14.0 + DSH rc.6 served at loopback port 3341. |
| Host/client load | PASS | Projection keys present; browser had no module/slot errors. |
| New session empty state | PASS | `/context` displayed all six categories at zero. |
| Ordinary assistant response | PASS | Second turn completed with exact `OK` response path and provider usage. |
| Multi-turn session | PASS | Two turns retained distinct request history and final context. |
| Reasoning response | PASS | First turn carried reasoning in the assistant stream/surface; Orca reported 105 provider reasoning tokens. |
| Tool call / result | PASS | Three request steps and tool/result surface categories rendered. |
| Aborted turn | PASS | Explicit cancel ended first turn; retained context was internally consistent and activity became Failed. |
| Session A/B independence | PASS | Empty and populated sessions displayed their own projections. |
| Refresh restore | PASS | Context selection and values returned after refresh. |
| Host restart restore | PASS | Context selection and provider prompt detail returned after process restart. |
| Liang coexistence | PASS | Liang effort slider visible throughout. |
| Orca Monitor/adapters coexistence | PASS | Token Monitor and Orca projections updated; no key/slot/reducer collision. |
| Browser console | PASS WITH EXPECTED WARNINGS | No plugin error; only connection-retry warnings from deliberate host restart. |
| Compaction/prune real lifecycle | NOT TESTED | No safe short-session trigger; upstream functional tests cover synthetic fold semantics only. |
| WinForms/WebView2 reference host | NOT TESTABLE SAFELY | Fixed production LocalAppData DSH_HOME boundary. |

No real user credentials or sessions were copied or read. A provider path was available in the isolated host and was exercised without inspecting or printing credential material.

## Correctness Spot-check

The populated session produced three first-turn requests before cancellation and one completed second-turn request.

| Check | Observed | Result |
| --- | --- | --- |
| Heuristic current total | `12,051` | Equals official `contextBreakdown`: system `1,573` + tools `6,670` + messages `3,808`. PASS. |
| Latest first-turn provider prompt | `12,331` | Equals Orca exact latest input `171` + cache read `12,160` + cache write `0`. No cache double count. PASS. |
| Latest first-turn provider output | `402` | Matches Orca exact output `402`. PASS. |
| Provider-anchored current occupancy | `12,703` | Matches official `contextPressure.projectedTokens`; UI displayed `12.7k`. PASS. |
| Model capacity | `1,000,000` | Came from `request/context` / official pressure projection; not a plugin hardcode. PASS. |
| Tool and header categories | system `1,573`, tools `6,670`, tool results `1,578` | Present independently in projection and UI. PASS. |
| Estimate labeling | Category values use `≈`; request detail distinguishes estimated total from actual prompt/output. | PASS. |
| Replay | Values survived refresh and host restart. | PASS. |

After the completed second turn, official pressure was `12,855` and projected next-request occupancy was `12,864`; cumulative official usage was uncached input `11,512`, cache read `34,048`, cache write `0`, output `1,455`. These cumulative values are intentionally different from Orca's latest-call snapshot.

## Performance / Persistence

- Each projection applies incrementally once per committed event; it does not rescan all sessions or all history on every render.
- State is isolated by DSH session identity. There is no global total.
- Request history is bounded to 1,500 steps and about 300 whole turns; events to 400; live nodes to 2,000 plus pinned injections; removed archive nodes to 400.
- Projection updates use shallow copy-on-change. UI receives whole projection values and performs ordinary per-render mapping/filtering over the bounded arrays. This is linear in the retained session window; there is no explicit memoized selector for all derived UI lists.
- Full system prompts/tool schemas are separated into `contextHeaders` and update only when request headers change, avoiding those large bodies on every event push.
- DSH's session projection cache owns persistence and restart replay. The plugin writes no extra database, session file or global state.

No obvious architecture-blocking performance fault appeared in the real two-turn/tool-call smoke. The generous bounds and whole-value push make very long sessions a future performance seam. The large distribution overhead observed here came from profile dependency reconciliation, not the 0.16 MiB plugin code.

## Privacy / Network

The Host projection reads and may expose locally to the same-origin Web client:

- full user prompts and assistant text;
- reasoning blocks as part of assistant content;
- tool-call names/arguments and tool-result content;
- full system prompt and tool schemas;
- injected context and model/provider metadata.

Source audit found no telemetry, no provider/API request and no session-content upload. Session material stays in DSH's normal local event/projection persistence and browser push path.

One external request exists: `src/client/latestVersion.ts` fetches `https://registry.npmjs.org/dsh-context/latest` lazily when the plugin-info card mounts, cached for one hour. Purpose is an update hint. It sends the ordinary HTTP request metadata/IP, not session content. Failure is silent, so Context functionality remains offline-capable. The check is not exposed as a configuration option in 0.19.1; a future default bundle would need to decide whether this unsolicited update check fits Orca policy.

Links to GitHub/releases are rendered but are only navigated when the user clicks. No CDN asset is required by the published runtime package.

## Distribution

### Build time

The exact prebuilt npm tarball can be pinned and installed into an Orca profile seed. A future integration would need to audit and control the resulting lock/workspace metadata, deduplicate or consciously accept the rc.8 peer graph, add direct/transitive notices, and design an Orca-owned existing-profile migration. None of that was implemented here.

### Runtime

With a complete seed, Context UI boots offline under bundled Node/DSH and needs no user npm, pnpm, git, network, native module or additional service. The npm version check is optional for function but currently automatic when its info card mounts.

### Updates

Upgrading the package is more than replacing its 0.16 MiB directory: it can change projection state versions, peer resolution, lockfile/workspace metadata and client slot contracts. Existing users would need a reviewed Orca migration that only touches the chosen community bundle without converting profile migration into a generic package manager.

## Known Failures and Gaps

- Upstream declares rc.8 session APIs; rc.6 works empirically but is outside its declared peer range.
- Fresh-clone `pnpm install --frozen-lockfile` and `pnpm build` passed. Running `pnpm test` before build failed because tests import the absent `lib/index.js`; after build the full Host/Client suite passed. The test script does not build its own prerequisite.
- The standard add grew the profile by about 49.68 MiB and 999 files and replayed Liang through pnpm.
- Project age and release cadence are too short for a default curated dependency today.
- Compaction/prune were not triggered in a real provider session.
- Reference-host E2E was not safely isolatable.
- Transitive licenses and repository-only media assets are not cleared for an Orca distribution.
- Automatic npm-registry version lookup has no opt-out in the audited release.

## Orca Decision

```text
DEFER
```

Reason:

- Product semantics, architecture, direct license, ordinary rc.6 compatibility, correctness and privacy boundary are strong enough to reject building an Orca Context Dashboard.
- The package is six days old at this snapshot, changed version during the test window, and declares hard rc.8 peer semantics while Orca is pinned to rc.6.
- Direct installation reconciles the full profile dependency graph, duplicates/pulls newer DSH packages and materially increases file count and size.
- Real compaction/prune and safely isolated WinForms E2E remain unverified.
- A default/optional curated bundle also requires transitive legal review and a deliberate existing-profile migration.

Distribution recommendation:

| Mode | Decision |
| --- | --- |
| Default bundle | No |
| Optional Orca bundle | No while deferred |
| User-installable only | Advanced/manual evaluation only; unsupported by Orca's zero-setup path |
| Fork | No; no Orca-specific semantic or presentation gap justifies sync cost |
| Orca Context UI | Do not build; reconsider the community package after the gates below |

Re-open criteria:

1. Orca upgrades beyond the current rc.6 DSH baseline or reaches a version covered by the upstream peer range.
2. Re-measure the exact `dsh-context` dependency graph against that new Orca DSH baseline.
3. Confirm that rc.8-peer duplication and profile size/file-count expansion no longer impose unacceptable distribution overhead.
4. Make a safely isolated WinForms/WebView2 E2E available.
5. Confirm that exact direct/transitive license and NOTICE review remains acceptable.

Real compaction/prune, long-session behavior, non-destructive migration and the automatic npm-registry version-check policy remain separate adoption checks. They do not create an Orca Context Dashboard or a dependency from MetricsAdapter to `dsh-context`.
