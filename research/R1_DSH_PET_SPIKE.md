# R1.3 dsh-pet Isolated Integration Spike

状态：Completed spike, decision `DEFER`
日期：2026-08-23
范围：仅使用隔离 `%TEMP%` DSH_HOME 与普通 `dsh web`；未修改 Orca production profile、migration、runtime、installer、release policy 或应用代码。

## Decision

```text
DEFER
```

`@linxin666/dsh-pet@0.2.9` 在 Orca 当前 DSH `0.1.0-rc.6` 的普通 `dsh web` 下可以启动、显示，并能与已注入的 Orca state adapters / Token Monitor 客户端 bundle 共存。该 smoke 是所覆盖路径上的**经验兼容**，不代表上游正式支持 rc.6：upstream declared DSH range is `>=0.1.1-rc.1`, while Orca is `0.1.0-rc.6`, outside that declared range. It has insufficient evidence for an Orca default or optional bundle: character redistribution rights are unresolved, rc.6 Settings cannot expose its configuration namespace, the host duplicates SessionEvent reduction and reads text/reasoning/tool payload for interactions, and its activity state is not a replay-safe per-session projection.

这不是否定其实现质量或普通 DSH Web 可用性。它是 Orca 当前的 distribution、privacy、compatibility 和 thin-layer 边界决策。

## Exact Baseline

| Item | Exact value |
| --- | --- |
| Repository | `https://github.com/zhu1090093659/dsh-web-ui` |
| Package | `@linxin666/dsh-pet` |
| Release | GitHub `v0.2.9` |
| Package version | `0.2.9` |
| Tagged commit | `117b0001b6c91d13245d0f239f0b7f33dadd95fa` |
| Release time | `2026-08-22T09:34:37Z` |
| npm publish time | `2026-08-22T09:32:30.706Z` |
| npm integrity | `sha512-9y8hCHHhdqoCWuch7gpdzw/gdMNqU5gt+ov0TME1XF5RTwnf1/310KcQAt5iiO5iijK28F7M7c7/SlGpmkX/TA==` |
| DSH | Orca pinned `@deepseek-ai/dsh@0.1.0-rc.6` |
| Upstream declared DSH range | `dsh.engines.dsh = >=0.1.1-rc.1` |
| Version-range result | `OUTSIDE DECLARED RANGE` |
| Node | Orca bundled `v24.14.0` |
| Test host | bundled Node + `dsh web --host 127.0.0.1 --port 3341` |
| Test DSH_HOME | `%TEMP%\orcadsh-r13-pet-home-a287d7f39d3649a9ad2dce206eea00a4` |

There is another public npm package named unscoped `dsh-pet@0.1.7` from `PC2005-cloud/dsh-pet`. It is a different, video-heavy desktop-pet product with no SessionEvent/activity integration. It is not the candidate evaluated in this report and should not be substituted silently for `@linxin666/dsh-pet`.

The audited upstream repository had progressed to commit `3d1387…` during the spike. Orca's evidence and any later re-evaluation must pin the release above, not `main` or npm `latest`.

The upstream development baseline reinforces the seam: `@deepseek-ai/dsh-session`, `dsh-settings`, `dsh-client-runtime`, `dsh-client-ui-conversation`, and `dsh-client-ui-settings` are each declared as `^0.1.1-rc.2` devDependencies. The ordinary rc.6 boot/smoke is therefore a compatibility exception observed on exercised paths only, not an upstream-supported baseline. It remains PASS for those exercised paths and must not be recast as a general rc.6 support claim.

## License and Asset Status

### Code

- Repository root and package `LICENSE` contain Apache License 2.0; `package.json` declares `Apache-2.0`.
- The published package carries its own `LICENSE` and `THIRD_PARTY_NOTICES.md`.
- The package notice attributes `assets/decorations/whale/whale-frames.png` to the DeepSeek Harness wordmark under MIT and includes the related notice.
- Direct runtime dependencies are `clsx@^2.1.1` and `schemastery@^3.18.0`; React/React DOM and DSH client/host APIs are peer/runtime framework dependencies. This spike did not complete a transitive dependency license audit.

The code evidence is sufficient for evaluation. It is not a complete legal-clearance statement for an Orca bundle.

### Assets

| Asset set | Format / approximate size | Package assertion | Orca distribution status |
| --- | --- | --- | --- |
| `assets/whale/spritesheet.webp` | WebP, 1.54 MiB | `whale-girl` manifest says `BSD-3-Clause` | BLOCKED: no independent character-art licence/provenance supplied |
| `assets/whale-refined/spritesheet.webp` | WebP, 2.20 MiB | refined manifest says `MIT` | BLOCKED: manifest field alone does not prove derivative-source rights |
| nine preview images | GIF, about 0.53 MiB total | no separate licence file | BLOCKED for Orca redistribution |
| whale status decoration | PNG + JSON, under 1 KiB | DeepSeek wordmark MIT notice supplied | reviewed direct attribution evidence exists |

The package contains no remote CDN asset requirement for its built-in sprite pets. Optional Live2D support needs a user-supplied Cubism Core under `$DSH_HOME/pets/.runtime`; it is not downloaded or bundled by this package, and any Live2D model/Core assets would need a separate audit.

## Architecture

### 1. State / projection layer

- The host does **not** register `sessionProjections` and has no projection key.
- `PetService` subscribes directly to `ctx.on('session/event', ...)` and holds a `Map<Session, SessionActivity>` in host memory. The visible pet follows the most recently meaningful session; only a bounded set of up to 12 session bubbles is retained.
- It consumes `turn/start`, `step/start`, `assistant/chunk` (`reasoning-delta`, `text-delta`), `assistant/message`, `tool/call`, `tool/result`, and `turn/end`; legacy `activity/status` is accepted but official events take precedence.
- A browser client polls same-origin `/api/pet/state` every two seconds while the document is visible. The host exposes `/api/pet/*` and `/pet/<id>/*` routes with loopback/same-origin guards.
- The state is not a DSH projection, has no replay cache and is reset to idle/no active session on host restart. User pet preferences/economy persist separately in `$DSH_HOME/pet.json`.

### 2. Pet state model and event mapping

The upstream phase set is exactly:

```text
idle, waiting, thinking, tool, review, done, failed
```

| Input | Upstream phase |
| --- | --- |
| `turn/start`, `step/start` | `waiting` |
| `assistant/chunk` reasoning delta | `thinking` |
| `assistant/chunk` text delta; `assistant/message` | `review` |
| `tool/call` | `tool` |
| successful final `tool/result` | `thinking`; remaining active tools remain `tool` |
| error `tool/result` | `failed` |
| `turn/end` completed | `done` |
| error / max-tokens / interrupted end | `failed` |
| blocked end | `waiting` |
| aborted end | `idle` |

The visual tracks are distinct from the semantic phases:

```text
idle, running-right, running-left, waving, jumping, failed, waiting, running, review
```

The built-in mapping is `idle→idle`, `waiting→waiting`, `thinking→running`, `tool→running-right`, `review→review`, `done→jumping` for 2.4 seconds then idle, and `failed→failed` for 2.4 seconds then idle.

### 3. Renderer / UI / assets

- React client with a root mounted under `document.body` using `createPortal`, not a conversation session slot.
- Fixed bottom/right DOM overlay, configurable drag position/size/visibility, `z-index: 2147483000`.
- Built-in renderer is CSS-background WebP spritesheet animation advanced by `requestAnimationFrame`; no Canvas is used for the bundled sprite path. Optional Live2D uses Pixi/Canvas.
- It has hover/status bubbles, interaction rewards, treats, affinity, whisper text, drag, hide/summon and global `pet.json` preferences.
- `settings.section` provides the intended settings entry. Under the tested rc.6 UI it showed an explicit message that DSH did not expose this plugin's settings namespace, so the form was unavailable. Direct local API and `pet.json` still worked.

## Comparison With Orca ActivityAdapter

| Concern | `@linxin666/dsh-pet` | Orca ActivityAdapter |
| --- | --- | --- |
| State names | Same seven names | `idle`, `waiting`, `thinking`, `tool`, `review`, `done`, `failed` |
| Per-session storage | Host-memory Map; visible state is global selector | Per-session DSH session projection |
| Replay / host restart | No; display restarts idle | Yes, projection/replay contract is the intended source |
| `tool/call` | `tool` | `tool` |
| successful `tool/result` | `thinking` or stays `tool` while tools remain | Orca event mapper remains authoritative; no dependency on pet |
| tool error | `failed` | independent Orca mapping |
| completed | `done`, then visual idle after 2.4 s | `done` remains snapshot state until later event/selectors change it |
| aborted | `idle` | current Orca mapping reports `failed` |

The state vocabulary matches, but semantics do not fully match. In particular, aborted behavior differs and the pet's temporary animations must not be mistaken for durable activity state. There are no extra upstream semantic phases and no Orca-only phase names.

**Decision: A. Orca ActivityAdapter should remain.** It supplies the stable per-session/replay-safe Orca contract. Making it consume this pet would reverse that boundary and lose persistence; removing it would make Token Monitor and future consumers depend on a global presentation plugin.

The two packages duplicate some event reduction today. The reduction cost is small in this spike, but it is real. A future pet candidate should consume a stable Orca/official projection rather than introduce another authoritative SessionEvent reducer.

## Custom Orca Character Feasibility

The registry/manifest (`petManifestVersion: 2`) can describe a `sprite2d` pet with asset path, geometry, tracks and phase sequences. A new pack can technically be supplied through the user/registry asset path without modifying the host's core state model.

| Desired change | Scope |
| --- | --- |
| Replace a compatible 9-track spritesheet and manifest | CONFIG + assets |
| Position, size, visible preference | NO CHANGE |
| Map the existing seven activity phases to existing visual tracks | CONFIG |
| Different sprite geometry / track durations | CONFIG, within manifest constraints |
| Simple Orca visual renderer with seven states | SMALL ADAPTER / new renderer is cleaner |
| Remove whisper/economy/affinity/global status behavior | RENDERER FORK or substantial upstream feature suppression |
| Adopt a materially different state or animation model | FULL FORK or independent small renderer |

So future Orca-owned assets could technically be registered, but they would inherit a fixed nine-track sprite model, character-specific interaction mechanics, host-global UI and direct text-aware event processing. That is too broad for a thin Orca presentation layer. A small renderer that consumes Orca's existing Activity projection would be lower-risk if an Orca Web Pet becomes an approved R3 goal.

## Ordinary `dsh web` E2E

All tests below used a fresh temporary DSH_HOME copied from the current seed. No real `%LOCALAPPDATA%\OrcaDSH`, credentials or user sessions were read or copied.

| Scenario | Result | Evidence / limit |
| --- | --- | --- |
| Standard profile add | PASS | `plugin --profile web add @linxin666/dsh-pet@0.2.9` with Orca bundled Node/DSH completed. |
| Host/client boot | PASS | rc.6 served loopback port 3341; `/api/pet/state`, `/api/pet/pets`, and built-in spritesheet returned 200. |
| Idle pet visible | PASS | browser DOM exposed button `鲸鱼娘（原版）`; built-in sprite route loaded. |
| Narrow 360×720 viewport | PASS WITH COMPOSITION RISK | overlay remained visible and did not cover the disabled sender in the empty-session page; it occupies the lower chat area and needs a real conversation UX pass. |
| Disable / re-enable | PASS | local `set-visible` route changed false then true. |
| Position/size persistence | PASS | `right=35`, `bottom=135`, `size=150` persisted in temporary `pet.json`. |
| Browser refresh | PASS | pet returned after refresh with persisted display state. |
| Host restart | PASS for plugin boot/preferences | pet reloaded and retained display preferences; activity state was idle/no active session as designed. |
| Reasoning, text, tool, completed, aborted, error | NOT TESTED in real provider turn | no test credential was used or inspected; pure compiled event-projection spot check covered the mapping table only. |
| Multiple turns and Session A/B | NOT TESTED in real E2E | no safe provider/workspace fixture was available. |
| Event replay equality | FAIL / NOT PROVIDED | no `sessionProjections`; host restart does not replay a durable pet phase. |
| Settings form | FAIL on tested rc.6 | settings page reported missing exposed configuration namespace; direct local API remained usable. |

The pure compiled mapping spot check emitted this sequence for synthetic events: `waiting → waiting → thinking → review → tool → thinking → done`; synthetic aborted mapped to `idle`, error to `failed`, done visual to `jumping` then idle, and failed visual to `failed` then idle after 2.4 seconds. This checks package behavior, not a provider E2E substitute.

## Coexistence

For coexistence only, the temporary profile was augmented with the current seed's `orcadsh-state-adapters` and `dsh-client-orca-token-monitor` directories and their existing bundle rows. This is a temporary fixture change, not an Orca migration or package design.

- Host loaded all three bundles without an observed loader failure.
- Pet button rendered. Token Monitor has no active session in this fixture, so its in-conversation labels cannot be visually asserted; no slot/key collision was observed.
- The pet mounts globally instead of `conversation.input.left`; it does not collide with the Monitor slot, but it can spatially overlap future chat content/modals because of the very high z-index.
- Both pet and Orca ActivityAdapter consume the same SessionEvent stream. This is reducer duplication; the pet should not become the source for Orca Metrics/Activity.

## Performance, Privacy and Network

### Performance

- Client polls state every two seconds only while visible and stops on `visibilitychange` when hidden.
- The built-in sprite runs a `requestAnimationFrame` loop; it respects reduced-motion preference. No large benchmark was run and no obvious idle/boot fault was observed.
- Optional Live2D has Canvas/Pixi per-frame cost and is out of scope for Orca distribution.
- Static bundled character assets total about 4.10 MiB. Standard profile installation changed the tested profile from 48 files / 43.98 MiB to 323 files / 53.60 MiB, a growth of 275 files / 9.62 MiB. That result includes pnpm reconciliation, package metadata and dependencies, not only the pet assets.

### Privacy / network

- Source audit found no telemetry, update check or remote asset/CDN fetch in the normal built-in pet path. Host/client traffic stays on same-origin loopback routes.
- The route guard is loopback/same-origin by default; with a separate remote-web plugin, a paired-device path can be allowed by that plugin family.
- This is **not state-only**: the host inspects assistant text and reasoning chunks for `WhisperEngine` content, and reads tool names/arguments for hints. It keeps activity/bubble/whisper copies in host memory and sends selected presentation state to the browser.

This local-only behavior is better than external upload, but full-content inspection is still incompatible with treating this candidate as a thin privacy-minimised Orca state facade.

## Distribution

| Concern | Result |
| --- | --- |
| Build-time bundle possible | Yes, with exact tarball/lock/profile design and complete licence review. |
| First start offline after complete seed | Technically yes. |
| User needs npm/pnpm/git after complete seed | No. |
| Standard user-side add | Requires pnpm/profile graph reconciliation; unsupported for Orca zero-setup. |
| Native module / system service | No required native module for bundled sprite path. |
| DSH version-range seam | `dsh.engines.dsh = >=0.1.1-rc.1`; Orca `0.1.0-rc.6` is `OUTSIDE DECLARED RANGE`. Ordinary rc.6 booted empirically on exercised paths only. |
| Existing-profile migration | Not designed or approved. |

The isolated add used the DSH-managed pnpm store at `%LOCALAPPDATA%\pnpm\store\v11`. That is suitable only as a spike installation path. It is not an Orca distribution plan and must not be confused with a bundled offline seed.

## Compatibility Matrix

| Seam | Status | Evidence |
| --- | --- | --- |
| DSH declared version range | OUTSIDE DECLARED RANGE | upstream declares `>=0.1.1-rc.1`; Orca is `0.1.0-rc.6` |
| DSH Host loader | PASS (empirical) | normal profile bundle booted on rc.6 for exercised paths; this does not mean upstream supports rc.6 |
| `sessionProjections` | FAIL / N/A | package does not register one |
| SessionEvent | PASS for static mapper; real provider lifecycle NOT TESTED | direct host listener observed in source; compiled mapping spot check |
| Client loader / exports | PASS | published client loaded and pet rendered |
| Client slots | PASS for `settings.section`; global pet uses portal | settings renderer has rc.6 namespace failure |
| Settings | COMPATIBILITY SHIM REQUIRED | rc.6 does not expose plugin namespace required by package form |
| Asset loading | PASS | local `/pet/whale-girl/spritesheet.webp` 200 |
| Profile bundle | PASS WITH DISTRIBUTION RISK | standard add succeeds but rewrites/reconciles profile graph |
| Session switching | NOT TESTED | no safe real-turn fixture |
| Refresh | PASS | global overlay returned |
| Host restart | PASS for boot/preferences; activity replay unavailable | phase reset to idle/no session |
| Orca WinForms reference host | NOT TESTABLE SAFELY | `App.cs` uses real `%LOCALAPPDATA%\OrcaDSH`; no test seam added |

## Final Architecture Recommendation

```text
Option E: DEFER / do not use as an Orca dependency today.
```

This does not select `entire plugin`, `state/projection only`, `renderer only`, or `small fork` for R3 today.

- **State projection reuse:** No. There is no projection and its host-memory/global selector would weaken Orca's contract.
- **Renderer reuse:** No current adoption. It is technically configurable but bundled behavior is broader than Orca needs and has high z-index/global UI risks.
- **Asset system reuse:** No distribution use until each Orca-owned asset has its own provenance and licence evidence. The manifest design is a useful interface reference only.
- **Default bundle:** No.
- **Optional Orca bundle:** No.
- **Fork:** No. A fork would inherit the code's broad interaction/privacy surface and maintenance burden without solving the source-of-truth issue.
- **Advanced manual use:** outside Orca zero-setup support, users may evaluate the exact upstream package at their own risk; Orca does not package, support, or endorse it.

Re-evaluate only after: (1) Orca reaches the declared upstream DSH range or upstream explicitly supports the selected Orca baseline; (2) a projection-first/state-only mode exists or a bounded privacy review justifies text-aware behavior; (3) a compatible Settings integration is demonstrated; (4) asset rights are independently documented; (5) an isolated real provider lifecycle including A/B/restart is available; (6) profile-size, migration and transitive licence evidence are re-measured; and (7) a safe WinForms/WebView2 E2E seam exists.

## Cleanup and Validation

- Temporary source clone, npm/package audit directory and isolated DSH_HOME remain under `%TEMP%`; they contain no copied real credentials or user sessions. Local cleanup is pending; no policy workaround or broad deletion was used.
- A prior unrelated unscoped package tarball audit directory also remains under `%TEMP%` and is not part of Orca source or distribution.
- Before completion, the R1.3 test host on port 3341 will be stopped and ports `3331`, `3332`, `3341`, `3445` checked free. No R1.3 node/DSH process may remain.
- No source tests were run from the upstream checkout. The executable evidence is the isolated host/client smoke and compiled mapping spot check described above.
