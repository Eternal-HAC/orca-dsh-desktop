# R2.2: OrcaIntensityStateV0 Client-side Mapper Implementation

Date: 2026-08-23
Scope: R2.2 approved implementation against the pinned `@deepseek-ai/dsh@0.1.0-rc.6` and Node `24.14.0`. This adds no renderer, write path, projection, persistence, routing, DSH core change, or production-pin change.

## Implementation location

`plugins/dsh-client-orca-intensity-state` is a dedicated Orca-owned browser bundle:

```text
package.json
cordis.patch.yml
lib/client.js
src/index.js
test/intensity-state-smoke.mjs
```

It is separate from `orcadsh-state-adapters` because that package owns host-side SessionEvent-derived Metrics and Activity projections. Intensity derives from browser-side ModelDirectory truth. Combining them would blur the host-projection and client-directory ownership boundary.

The build seed and existing-profile migration include the package. The only `App.cs` change adds this already-established Orca-owned bundle to the existing incremental migration list; it does not alter DSH lifecycle, user data, or model selection behavior.

## Public client API

The browser ModuleLoader entry `dsh-client-orca-intensity-state` exports:

```js
mapOrcaIntensityState({ sessionId, directoryState })
createActiveOrcaIntensityStateSelector(ctx)
```

`mapOrcaIntensityState` is pure: it reads only the supplied already-read directory snapshot and returns the frozen `OrcaIntensityStateV0` shape. It does not fetch, subscribe, persist, mutate a session, invoke `session.selectModel`, read localStorage, or inspect DOM.

`createActiveOrcaIntensityStateSelector(ctx)` is the one consumer binding. It reads `ctx.sessions.list.current` only to choose the active session, then uses `ctx.modelDirectories.directoryFor(sessionId).store` for that exact ordinary session. It returns `{ store, dispose() }`. A future renderer owns its lifecycle and calls `dispose()` when unmounted.

On the first binding only, the selector calls the existing DSH `directory.load()` when its store is `idle`. It does not add an RPC endpoint or poll. The rc.6 `ModelDirectoryResolver` performs later refreshes for adapter/settings updates and connection resets; the selector follows its shared store.

## DSH source consumed

```text
ctx.sessions.list.current
  -> active-session consumer choice only
ctx.modelDirectories.directoryFor(sessionId).store
  -> ModelDirectoryState.current (Host ModelSelection)
  -> matching provider/model from ModelDirectoryState.groups
  -> exact model.reasoning.efforts / defaultEffort
```

The active selector returns `unknown` for addressed subagent sessions because rc.6 does not expose an ordinary ModelDirectory for them. It does not manufacture an `unsupported` model state.

## Mapping and availability rules

| Condition | Result |
| --- | --- |
| no active session | `no-session`; identities and catalog are empty |
| directory missing, idle, loading, or selecting before a usable selection | `loading` |
| exact selected model has no `reasoning` metadata | `unsupported`, empty catalog |
| valid reasoning metadata and null or listed selected raw ID | `ready` |
| non-null raw selected ID missing from current efforts | `stale`; raw ID retained, position `null` |
| malformed metadata, non-ordinary session, failed match, or invalid shape | `unknown` |

`availableEfforts` preserves the exact upstream array order. Each entry has `normalizedPosition = index / (count - 1)`; a single entry is `0`. The value is finite in `0..1`, and means ordered catalog position only. It is not a reasoning percentage or semantic strength.

Unknown vendor IDs are opaque and map by position without an ID switch. Empty names remain upstream strings. Missing descriptions become `null`. A non-string required ID/name or description is `unknown`. A raw upstream default ID is preserved even when it is absent from the effort list, because the mapper must not repair it.

Duplicate effort IDs are `unknown`: one raw `reasoningEffort` cannot safely choose one of two advertised positions, so the mapper returns no catalog rather than silently choosing the first or second row. `reasoning` metadata with an empty `efforts` list is also `unknown`. It differs from `unsupported`, which is reserved for an exact current model whose `reasoning` metadata is absent.

## Selected/default behavior

- `selected.effortId` is exactly `ModelSelection.reasoningEffort`; when absent it remains `null`, including when `defaultEffortId` exists.
- `defaultEffortId` is exactly matching `model.reasoning.defaultEffort`, or `null` when absent.
- A stale selected ID is never replaced with default, nearest, or first effort.
- `off` is an ordinary raw effort ID and remains distinct from a null selection, `unsupported`, and `stale`.

No R2.2 API writes a reasoning effort. DSH remains the persistence and submission owner.

## Reactivity and limits

The selector follows active-session changes through `sessions.list`, then follows the selected session's shared ModelDirectory store. This covers session changes, model selection changes, reasoning effort changes, directory refreshes, adapter/settings refreshes, and connection-reset reloads handled by the rc.6 resolver.

Selector lifecycle is narrow and consumer-owned. Loading the bundle only evaluates its ModuleLoader factory and exposes its API; it creates no snapshot store, selector, session listener, directory listener, polling loop, or state write. `createActiveOrcaIntensityStateSelector(ctx)` is the first point that creates a store and subscriptions. On an `A -> B -> A -> B` transition it first disposes the old directory listener, then subscribes to the new active directory. Same-session list notifications keep the existing listener. `dispose()` is idempotent and removes both the session-list and current-directory listeners; later list or directory updates cannot publish a new snapshot.

The package stores no snapshots or selections. Reload/reconnect/session switching re-derives from DSH client state. There is no projection, SessionEvent reducer, Metrics/Activity/Token Monitor dependency, or Liang frame/0–30 input.

R2.2 provides no renderer, drag preview, recommendation, routing, auto-apply, source field, or persistence. `previewIntensity` remains a future renderer-local transient concern; recommendation remains a future independent policy that must never silently override selected state.

## Seed and migration boundary

`build.ps1` copies the exact local package files (`package.json`, `cordis.patch.yml`, `src`, and `lib`) into the profile seed and appends `dsh-client-orca-intensity-state` after the existing bundle rows. It does not download a dependency for this package, change the Node or DSH pins, or change the Liang package path/version.

`App.cs` reuses the existing `MigrateBundledWebPlugin()` helper shared with `orcadsh-state-adapters` and Token Monitor. For an existing web profile it refreshes only this Orca-owned package directory, then appends the bundle ID only when absent. The helper preserves existing bundle order, leaves third-party bundles intact, and does not recreate DSH_HOME, reset settings, touch credentials/sessions, run `plugin add`, invoke pnpm, or reinstall the dependency graph.

The client entry is `./client`, registered through a DSH browser ModuleLoader factory. Its package manifest injects only `@deepseek-ai/dsh-client-runtime` and `@deepseek-ai/dsh-client-ui-model-selection`: runtime supplies the session/store interfaces, while the model-selection bundle owns the rc.6 `modelDirectories` service. It does not pre-inject theme, locale, settings, slots, or conversation UI.

## Tests and compatibility

`test/intensity-state-smoke.mjs` loads the actual browser ModuleLoader entry in a Node VM and verifies:

- no-session and unsupported states;
- rc.6 `off/high/max` positions `0/0.5/1`;
- static target portability fixture `off/low/high/max` positions `0/1/3/2/3/1`;
- single effort and unknown opaque IDs;
- valid, null, stale, and default-different-from-selected cases;
- duplicate IDs, empty name, undefined description, and invalid metadata handling;
- empty effort metadata handling;
- active-session selector reactivity and one initial DSH directory load;
- dormant bundle loading, deterministic pure mapping, `A -> B -> A -> B` listener teardown/rebinding, inactive-directory isolation, same-session no-duplicate listener behavior, and idempotent disposal.

The target fixture checks mapper portability only. It does not claim target runtime compatibility.

## Validation result

| Check | Result | Evidence boundary |
| --- | --- | --- |
| `intensity-state-smoke.mjs` | PASS | Actual browser entry evaluated in a Node VM with a fake ModuleLoader/runtime store; covers contract fixtures and selector subscriptions. |
| Existing state-adapter smoke | PASS | `orcadsh-state-adapters/test/adapter-smoke.mjs`; Metrics/Activity reducer surface remains unchanged. |
| PowerShell AST | PASS | `build.ps1`, package-release/policy/baseline scripts parse successfully. |
| Full development build | PASS | Rebuilt `dist/DeepSeekHarness` and `dist/DeepSeekHarness-Setup-v0.2.0-win-x64.exe` before the later mapper-only lifecycle audit. |
| Release baseline | PASS | Pinned Node/DSH, all four profile bundles, client entry, user-data scan, and direct redistribution evidence. |
| Isolated ordinary rc.6 host smoke | PASS | Fresh temporary DSH_HOME copied only from the seed; `dsh --profile web --host 127.0.0.1 --port 3341` returned HTTP 200. Its web manifest listed the intensity bundle and `/plugins/dsh-client-orca-intensity-state/client.js` served the mapper API. |

No renderer was added, so there is no visual Intensity UI assertion. The ModuleLoader entry and selector are covered by the VM harness; the isolated host smoke proves rc.6 profile composition and server-side client bundle delivery. It does not claim a target `0.1.1-rc.2` runtime PASS, a WinForms WebView2 E2E, or a user data retention test.

The controlled smoke node was stopped and ports `3080`, `3331`, `3332`, `3341`, and `3445` were confirmed free afterwards. Two no-credential temporary seed/smoke directories remain under `%TEMP%` because the local execution policy rejected recursive cleanup in this session; they are local cleanup pending and are not repository files.

## Post-implementation lifecycle audit

The pre-commit audit added no product surface. It changed mapper validation so duplicate effort IDs and an empty `reasoning.efforts` list now return `unknown`; the earlier full build therefore predates this mapper-only correction. Build/migration logic was unchanged, so the audit reran both package tests, release-baseline validation, and `git diff --check` without another full Setup build.

The selector test now proves the following against listener-counting stores:

```text
active A -> B -> A -> B
```

- previous directory listeners are removed before the next one is added;
- repeated same-session list notifications leave one listener, not an accumulating set;
- an inactive directory update leaves the active snapshot unchanged;
- a current directory update reaches the active snapshot;
- double `dispose()` is safe and leaves both list and directory listener counts at zero;
- after dispose, either source can update without changing the selector snapshot.

The ModuleLoader factory is also evaluated before any selector is created and the test asserts zero runtime snapshot-store creations at that point. This confirms default bundle load is dormant: exporting the API performs no subscription, ModelDirectory binding, polling, or write. A future consumer explicitly calls the selector to start the bounded subscriptions.
