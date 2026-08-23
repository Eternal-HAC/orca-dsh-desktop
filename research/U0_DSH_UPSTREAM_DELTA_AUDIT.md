# U0: DSH Upstream Delta Audit

**Audit date:** 2026-08-23
**Scope:** Read-only comparison of Orca's shipped DSH runtime with a pinned upstream candidate. No production runtime, profile seed, plugin, build, installer, or release-policy file was changed.

## Exact Versions

| Role | Value |
| --- | --- |
| Orca base package | `@deepseek-ai/dsh@0.1.0-rc.6` |
| Orca base source anchor | `fb82698709c39f1860b0ab0ed147e1fa30c1d5d0` (the rc.7 release comparison starts at this rc.6 release merge) |
| Orca bundled Node | `v24.14.0` |
| npm `latest` | `0.1.1-rc.2` |
| npm `next` | `0.1.1-rc.2` |
| Newest GitHub release/tag | `dsh-v0.1.1-rc.2`, prerelease |
| Selected candidate | `@deepseek-ai/dsh@0.1.1-rc.2` |
| Selected source tag/commit | `dsh-v0.1.1-rc.2` / `b150a551b8d465e31e418e1b2eaf5e79bbb7d28e` |
| GitHub release published | 2026-08-21T12:35:08Z |
| npm package published | 2026-08-21T12:42:19.422Z |

The GitHub releases queried for this audit are prereleases, so GitHub's stable-only `releases/latest` endpoint has no result. The candidate is selected because npm `latest`, npm `next`, and the highest upstream tag converge on the same exact prerelease. A future upgrade must pin the exact version and commit, never a floating dist-tag.

## Release/Tag Timeline

| Version | Tag commit | npm publish time | Orca-relevant changes |
| --- | --- | --- | --- |
| `0.1.0-rc.6` | base anchor above | 2026-08-13T12:35:03.812Z | Current Orca production baseline. |
| `0.1.0-rc.7` | `99f6f02fecdb7dff40c3fbc9470f5907c29f74ca` | 2026-08-17T11:50:59.194Z | Plugin-owned settings cards; `low` DeepSeek reasoning effort; Node PTY beta and job-panel changes. |
| `0.1.0-rc.8` | `141eb6fef83422698aef7a981029e843e8161534` | 2026-08-19T15:41:29.655Z | DeepSeek native image request path; persistent Windows PowerShell; `dsh web` automatic browser opening; explicitly incompatible SQLite storage format. |
| `0.1.1-rc.1` | `528c682e061696f5a160f363f236ecbf53cbd006` | 2026-08-21T06:49:18.639Z | Adds `DeepSeek-V4-Flash-Vision-Exp` to the DeepSeek adapter catalog. |
| `0.1.1-rc.2` | `b150a551b8d465e31e418e1b2eaf5e79bbb7d28e` | 2026-08-21T12:42:19.422Z | DeepSeek Files API upload/reuse and image preprocessing to model limits. |

## Model Changes

| Aspect | rc.6 | Candidate | Classification |
| --- | --- | --- | --- |
| Default DeepSeek models | `deepseek-v4-flash`, `deepseek-v4-pro` | Same two, plus `deepseek-v4-flash-vision-exp` / `DeepSeek-V4-Flash-Vision-Exp` | BENEFICIAL |
| Vision model modalities | N/A | `['text', 'image']` | BENEFICIAL |
| Per-model image metadata | N/A | `imagePixelBudget`, `imageMaxBytes`, optional `imageDetail` | BENEFICIAL |
| Native image request path | N/A | Adapter serialization plus Files API upload/reuse and preprocessing | BENEFICIAL |
| Model context window | Default model entries use existing `DEFAULT_CONTEXT_WINDOW` | Same for all three default entries | NO MATERIAL CHANGE |
| Tool capability metadata | No model-specific tool flag found | No model-specific tool flag found | NO MATERIAL CHANGE |

The candidate preserves user-configurable model catalogs. The new metadata proves adapter-side support, not provider entitlement or endpoint availability.

## Vision Status

| Question | Status | Evidence / boundary |
| --- | --- | --- |
| DSH adapter support | **PRESENT** | Candidate adds a default vision catalog entry, image modality validation, native image serialization, image-size handling, Files API upload/reuse. |
| Model catalog support | **PRESENT** | Default entry is `deepseek-v4-flash-vision-exp`, displayed as `DeepSeek-V4-Flash-Vision-Exp`. |
| Official DeepSeek endpoint support | **NOT CONFIRMED** | This audit made no credentialed/provider request. Release notes and adapter source cannot establish that a user's account/endpoint accepts the model or Files API. |
| Usable immediately after an Orca target upgrade | **NOT GUARANTEED** | It would be catalog-visible and adapter-capable, subject to a valid credential and actual provider availability. Full Orca upgrade E2E remains required. |
| Extra user model configuration | **Not required for the default catalog entry** | A user may still need endpoint/account access; custom catalogs/gateways can change this. |

No live provider call was made and no real API key was read.

## Reasoning Effort Changes

| Question | rc.6 | Candidate | Result for R2 |
| --- | --- | --- | --- |
| Config IDs | `off`, `high`, `max` | `off`, `low`, `high`, `max` | New raw ID `low`. |
| Schema form | String union | String union | No numeric intensity field. |
| Default when omitted | `high` | `high` | No material default change. |
| Thinking disabled | `off` only | `off` only | Preserve absent/disabled handling. |
| Model-specific differing default effort lists | Not found in default catalog | Not found; vision shares adapter policy | No evidence for a new per-model scale. |
| Numeric weight / visual scale | Not found | Not found | Orca must not infer a 0–30 or vendor numeric scale. |
| Recommended field | Not found | Not found | `recommendedIntensity` stays Orca-owned. |
| Order reliability | Client renders host-provided `reasoning.efforts` array order | Same design | Treat order as display/catalog order, not durable semantic weight. |

The raw effort ID remains the upstream value sent to DSH. Model selection may replace the active model's available effort list; callers must re-resolve the chosen effort and tolerate absent/null effort data.

**R2 conclusion:** `OrcaIntensityState` can be designed against rc.6 before an upgrade. Its approved contract already forbids hard-coding Liang's 0–30 scale, keeps `effortId`, and separates selected from recommended state. The candidate adds no upstream numeric or recommendation contract that R2 needs.

## SessionEvent Delta

The audit checked the existing Orca reducer seams: `session/event`, `turn/start`, `step/start`, `assistant/chunk`, `assistant/message`, `tool/call`, `tool/result`, and `turn/end`.

| Seam | Static comparison result | Upgrade posture |
| --- | --- | --- |
| Event names named above | No targeted release-note or source evidence of rename/removal | NEEDS E2E |
| Text/reasoning chunk vocabulary | Candidate token-meter still consumes `assistant/chunk` usage chunks; normal chunk pipeline remains present | NEEDS E2E |
| `assistant/message.data.usage` | Still consumed by candidate token-meter | LIKELY COMPATIBLE, verify E2E |
| Tool events | Names remain present in target source/tests | NEEDS E2E for lifecycle ordering |
| Abort/failure completion | Target tests still model `turn/end.data.reason.kind`, including `aborted` and `error` | LIKELY COMPATIBLE, verify E2E |

This is not a target runtime assertion. Candidate load/runtime smoke did not complete, so event field shapes and ordering remain an upgrade-spike verification item.

## Usage Delta

Candidate token-meter still accepts provider usage from both paths:

```text
assistant/chunk.data.chunk.type === 'usage' -> chunk.usage
assistant/message.data.usage                 -> message usage
```

It still models `inputTokens`, `outputTokens`, optional `cacheReadTokens`, and optional `cacheWriteTokens`. It does not make a DeepSeek-specific `reasoningTokens` field reliable. Orca must continue to show reasoning tokens as null when the provider does not independently provide them.

The token-meter implementation and projections changed substantially, including replacement-aware same-step usage handling. Existing Orca adapter observations remain valid for rc.6; a target upgrade needs normal provider-usage and cache-read E2E.

## Projection Delta

Both base and target register the same official projection names when `sessionProjections` is present:

```text
tokenUsage
contextPressure
contextBreakdown
```

The candidate improves internal projection/cache mechanics and token-meter folds, but no official projection provides Orca's presentation activity enum or a reliable DeepSeek reasoning-token bucket. It creates an opportunity to review whether `MetricsAdapter` can read official `tokenUsage` more directly in a future approved upgrade spike; it does not justify a U0 refactor.

`sessionProjections`, client projection values, and history/list restoration remain upgrade smoke seams. Current Orca code is rc.6-compatible only until target E2E proves otherwise.

## Client API Delta

Candidate source contains the needed API families:

```text
conversation.input.left
conversation.view
conversation.input.overlay
sessions.binding(sessionId)
sessions.get(...)
settings.section
settings.plugin.item
settingsScope
```

However, rc.6 to target includes substantial changes in client runtime session handling, conversation input/slot contracts, module loading, and settings UI. Presence is not compatibility proof.

| Orca consumer | Target impact | Classification |
| --- | --- | --- |
| `orcadsh-state-adapters` | Exact peer pins `@deepseek-ai/dsh-session-projection` to `0.1.0-rc.6`; target ships `^0.1.1-rc.2`. | COMPAT SHIM REQUIRED, then E2E |
| `dsh-client-orca-token-monitor` | Uses runtime/conversation UI, `sessions.binding(sessionId)?.session.projections`, and `conversation.input.left`. | NEEDS E2E |
| Liang intensity skin | Injects runtime, conversation, model-selection, settings, theme, locale, and remotes packages. | NEEDS E2E; larger client change surface |

## Settings Delta

rc.7 added an upstream plugin-owned settings-card flow. Candidate source explicitly provides `settingsScope`, `settings.section`, and `settings.plugin.item` through the settings/client-plugin layer. This is favorable evidence that the old dsh-pet Settings namespace limitation may improve.

It is **not** proof that dsh-pet's exact configuration namespace works on target. That seam requires a target isolated profile plus WebView/client E2E. No current Orca-owned plugin depends on a settings namespace for its runtime data path, so no immediate R2 dependency exists.

## Credentials Delta

Candidate adds/expands an authorization package and materially changes credentials-related source. Its DeepSeek adapter still resolves a credential per request and defaults its environment reference to `DEEPSEEK_API_KEY`; source comments state a missing key fails at request time rather than plugin load.

No real Orca credential file was read. The audit found no safe evidence that an in-place rc.6 Orca `DSH_HOME` credential/session state survives the target storage and authorization evolution. Credential retention and settings-auth UI behavior are **UNKNOWN** until a dedicated isolated upgrade fixture proves them.

## Plugin Lifecycle Delta

The candidate retains the profile model used by Orca: `$DSH_HOME/profiles/<name>/package.json`, ordered `dsh.profile.bundles`, and `cordis.patch.yml` layers. It also retains a `dsh plugin` command that forwards user package operations to `pnpm` in the profile directory.

The target does **not** bundle a private `pnpm` for Orca users. Target source still reports `pnpm not found on PATH` and documents pnpm >=10 `allowBuilds` friction for git-hosted plugin installs. It does not remove Orca's separate private-pnpm/consent/trust requirements. R1's market decision remains unchanged.

## Windows/Node Delta

| Area | Evidence | Classification |
| --- | --- | --- |
| Candidate Node requirement | Root declares `^22.19.0 || >=24.0.0`. Orca's bundled `v24.14.0` satisfies it. | KEEP Node 24.14.0 |
| Windows terminal behavior | rc.7 updates node-pty; rc.8 adds persistent PowerShell support. | BENEFICIAL but NOT REPRODUCED in Orca host |
| WebView host | No upstream WinForms/WebView2 contract found. | UNKNOWN / host E2E required |
| `dsh web` port | Target web bundle defaults to `127.0.0.1` and port `3080`. | NO MATERIAL CHANGE |
| Browser opening | rc.8 makes `dsh web` open the default browser; target supports `--no-open`. | COMPAT SHIM REQUIRED for Orca host |
| SQLite sessions | rc.8 release explicitly says storage format is incompatible; target moves schema `15` to `17` and adds packed/compressed physical rows. | BLOCKING for in-place upgrade without migration/retention plan |

Current [App.cs](../src/App.cs) launches `dsh ... web` without `--no-open`. A target upgrade must add that argument in a separately approved upgrade change, otherwise the desktop host can open an unwanted external browser. U0 does not change it.

## R1 Candidate Version-Gate Impact

| Candidate | Declared gate | Does `0.1.1-rc.2` satisfy it? | Product decision impact |
| --- | --- | --- | --- |
| `dsh-context@0.19.1` | `@deepseek-ai/dsh-session ^0.1.0-rc.8` | **No**, per npm semver prerelease-range evaluation | Version seam remains; DEFER unchanged. |
| `@linxin666/dsh-pet@0.2.9` | `dsh >=0.1.1-rc.1` | **Yes**, per npm semver evaluation | Version gate resolves only; Settings shim, asset rights, private pnpm, host E2E, and product decision remain. DEFER unchanged. |

The dsh-pet result does not make rc.6 officially compatible and does not approve adoption, bundling, or a fork.

## Upgrade Risk Matrix

| Area | rc.6 -> candidate | Orca impact |
| --- | --- | --- |
| Model catalog | Vision entry and image metadata added | BENEFICIAL; endpoint availability unconfirmed |
| Reasoning efforts | `low` added; raw string IDs retained | BENEFICIAL; R2 must stay dynamic |
| SessionEvent | No identified rename/removal on Orca paths | UNKNOWN pending target E2E |
| Usage schema | Both usage paths remain; meter fold changes | NEEDS E2E |
| Projection API | Same official names, changed internals | NEEDS E2E |
| Client API | Large runtime/conversation/slot evolution | NEEDS E2E |
| Settings | Plugin-card and scope facilities improve | BENEFICIAL but exact community seam needs E2E |
| Credentials | Authorization/credentials source changes | UNKNOWN; retention fixture required |
| Plugin lifecycle | Profile/bundle design retained; still external pnpm | NO MATERIAL CHANGE to Orca policy |
| Node | Node 24.14.0 satisfies candidate engine | NO MATERIAL CHANGE |
| Windows | Persistent PowerShell is new | BENEFICIAL, NOT REPRODUCED |
| `dsh web` browser launch | Automatically opens browser by default | COMPAT SHIM REQUIRED (`--no-open`) |
| SQLite sessions | Explicitly incompatible storage format | BREAKING for in-place user-state upgrade |

## Minimal Isolated Target Smoke

An isolated temporary audit root was created under `%TEMP%`; it contained only upstream source/tarballs and no copied credentials, sessions, or user profile. A target `npm install --omit=dev --prefix <temp> @deepseek-ai/dsh@0.1.1-rc.2` did not complete within the audit window and was stopped. Consequently:

| Check | Status |
| --- | --- |
| Target package metadata / source static audit | PASS |
| `dsh --version` on target runtime | NOT COMPLETED |
| Target `dsh web` boot / profile boot | NOT COMPLETED |
| Target session/service availability | NOT COMPLETED |
| Target settings/client shell | NOT COMPLETED |
| Orca adapters/Token Monitor injected into target profile | NOT COMPLETED |

This is an incomplete local package-install setup, not evidence of an upstream DSH failure. No target DSH process was launched.

## Decision

# KEEP RC.6 FOR R2

R2 can freeze `OrcaIntensityState v0` against current rc.6 semantics because the candidate preserves raw effort IDs and supplies no upstream numeric/recommendation contract that R2 needs. The new `low` ID strengthens the requirement to map dynamically and preserve user choice.

Upgrading before R2 would add disproportionate risk: incompatible SQLite persistence, no completed target load smoke, a required `--no-open` host change, an exact state-adapter peer update, and a broad client/slot regression surface. A separately approved DSH upgrade spike should first establish an isolated target runtime, backup/migration and retention policy, `--no-open`, state-adapter peer reconciliation, and full Orca WebView E2E.

## Audit Boundaries and Sources

- Official npm metadata for `@deepseek-ai/dsh` supplied dist-tags and publish timestamps.
- Official `deepseek-ai/deepseek-harness` tags/releases supplied commits and release notes.
- Candidate source was a shallow clone at the exact selected tag; base comparison uses the rc.6 merge anchor shown by the rc.7 official release comparison.
- Current Orca package manifests and `src/App.cs` were read statically.
- No production runtime data, credential, provider endpoint, or user DSH profile was accessed.

## Cleanup

At audit end, ports `3080`, `3331`, `3332`, `3341`, and `3445` were free. No `node.exe` process had a command line rooted in the temporary audit directory. The temporary audit directory remains for local cleanup; it contains upstream source and npm tarballs only, with no real credentials or sessions.
