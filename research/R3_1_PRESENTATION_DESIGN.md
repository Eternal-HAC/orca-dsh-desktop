# R3.1: Orca Web Presentation Design Specification

Date: 2026-08-23
Status: Design specification for review; no renderer implementation is authorized by this document.
Runtime baseline: `@deepseek-ai/dsh@0.1.0-rc.6`, Node `24.14.0`.

## Scope and Evidence Boundary

This document specifies the first Orca-owned, read-only Web presentation surface. It consumes the already reviewed Orca state boundary:

```text
Required: DshActivitySnapshot + OrcaIntensityStateV0
Optional: DshMetricsSnapshot only after a concrete presentation need is reviewed
```

It does not change the contracts, reducers, mapper, profile seed, WinForms host, DSH core, Liang, or any effort write path. The evidence used here is limited to the pinned rc.6 client contracts and existing Orca clients:

- Token Monitor renders through the verified rc.6 `conversation.input.left` slot and consumes the per-session Metrics/Activity projections.
- Liang's development bundle renders its effort control in `conversation.input.right`; it also has a non-interactive fixed background layer (`z-index: 0`, `pointer-events: none`).
- `dsh-client-orca-intensity-state` provides a per-active-ordinary-session selector whose output is re-derived from the shared ModelDirectory. It has no UI and no write API.

The ordinary rc.6 `dsh web` bundle/load smoke is PASS. This is not visual rendering evidence, WinForms WebView2 evidence, or `0.1.1-rc.2` runtime compatibility evidence.

## Product Role

### Candidate comparison

| Direction | Information density | Recognition | Space / Token Monitor conflict | Future character path | Asset dependency | Implementation cost |
| --- | --- | --- | --- | --- | --- | --- |
| A. Status companion, icon only | Low | Medium | Lowest | Medium | Low | Lowest |
| B. Status panel / card | High | Low | Highest; duplicates status-oriented UI near Token Monitor | Low | None | Medium |
| C. Hybrid: abstract glyph plus concise text | Sufficient for state distinction | High without a character system | Low when compact and collapsible | Keeps a future legal character path open without depending on one | Low; inline Orca-owned geometry only | Low to medium |

### Decision

Choose **C, a compact Hybrid Status Companion**. It is a small visual companion rather than a dashboard, Pet engine, or reasoning control. It combines:

1. an abstract, non-character Orca glyph that carries Activity through posture and motion;
2. a short, explicit Activity label that preserves recognizability; and
3. a discrete reasoning-mode marker that carries Intensity separately.

This gives the user a reliable session-status cue without duplicating Token Monitor telemetry. It does not pre-commit Orca to a character renderer or unlicensed artwork.

## Visual Hierarchy and State Composition

```text
ActivitySnapshot
  -> primary temporal channel: glyph posture, bounded motion, status label

IntensityStateV0
  -> secondary structural channel: ordinal notches, selected/default marker,
     availability treatment
```

Activity owns the primary visual state. Intensity never changes the same motion property; it only changes the discrete mode track or its availability treatment. Thus a `thinking + ready` companion can show deliberate thinking motion while its static mode track indicates the selected ordinal position.

`normalizedPosition` is a position within the current adapter-provided ordered catalog. It must never be labelled or implied as a percentage, strength score, power meter, or semantic distance. The renderer renders one notch per `availableEfforts` entry, not a continuous 0–100 scale and never Liang's 0–30/frame system.

## Activity Semantics and Priority

| State | Meaning | Posture / icon | Normal motion | Text requirement | Priority | Transition behavior |
| --- | --- | --- | --- | --- | --- | --- |
| `idle` | No current work visible for this session | Resting glyph | Very slow breathing | `Idle` | 1 | Settle from terminal state after its hold period |
| `waiting` | A request has been submitted and the session is awaiting work | Forward-facing / expectant glyph | One restrained anticipation pulse, then still | `Waiting` | 3 | Debounce short appearances to avoid a flash before `thinking` |
| `thinking` | Reasoning or generation work is active | Focused glyph | Deliberate low-frequency orbit / fin movement | `Thinking` | 4 | Respond promptly after debounce; may return after tool work |
| `tool` | A tool call is in progress | Small utility/tool badge on glyph | One short action pulse, then a quiet hold | `Using tool` | 5 | Preserve a short visible hold so rapid tools remain distinguishable |
| `review` | The assistant is preparing or streaming its response | Open / settling glyph | Gentle outward settling motion | `Responding` | 4 | Cross-fade from thinking/tool; do not use the same spinner |
| `done` | The last turn completed | Confirmed/resting glyph plus check icon | One brief confirmation, then still | `Done` | 2 | Hold briefly before returning to idle if no newer state arrives |
| `failed` | The current turn failed or was aborted according to the Activity contract | Stopped glyph plus alert icon | No looping motion | `Failed` | 6 | Enter immediately; remain visible until the adapter supplies a later state or the active session changes |

### Flicker and transient-state rules

These are design values for R3.2 validation, not changes to `DshActivityAdapter`:

- `waiting` may be delayed by about 250 ms. If `thinking`, `tool`, `review`, `done`, or `failed` arrives before then, do not paint a one-frame waiting state.
- `tool` should remain visible for at least about 400 ms when a rapid follow-up state arrives, except `failed`, which has priority and replaces it immediately.
- `done` should remain visible for about 1,200 ms before visually settling to `idle`, unless a new non-idle Activity snapshot arrives first.
- `failed` is never debounced or auto-converted to `done`; it is replaced only by a subsequent adapter state for the active session.
- Other changes cross-fade posture over roughly 160–220 ms. No state may use high-frequency flashing.

The current Activity snapshot remains the source of truth. These presentation holds are local visual smoothing only and must be cleared on session switch, unmount, and refresh.

## Failed State

`failed` is explicit and accessible:

- a stable alert icon plus the text `Failed` are required;
- a warm error color may support the meaning, but color alone is insufficient;
- all ongoing glyph animation stops, avoiding a misleading “still processing” signal;
- it remains visible under the rule above and has no retry, inspect, or write control in R3;
- the companion must not attempt to classify provider failures beyond the supplied Activity state.

## Intensity Semantics

### Availability treatment

| Availability | Visible behavior | Label / fallback | Treatment |
| --- | --- | --- | --- |
| `no-session` | Hide the entire companion | None | No active ordinary session is a normal empty state, not an error |
| `loading` | Show compact companion | `Preparing reasoning modes` | Muted skeleton track; no fabricated selected/default marker |
| `ready` | Show full companion | See mode treatment below | Discrete ordinal track and exact upstream display names |
| `unsupported` | Show compact companion | `No reasoning modes for this model` | Neutral disabled track with an unavailable icon; distinct from `off` |
| `stale` | Show compact companion | `Reasoning selection needs refresh` | Low-distraction warning badge and broken/unmatched selected marker; never snap to another effort |
| `unknown` | Show compact companion | `Reasoning state unavailable` | Neutral uncertainty icon and no catalog inference |

The companion remains visible for loading, unsupported, stale, and unknown because the Activity signal can still be useful. `no-session` hides it: a dormant global mascot would imply a global session state that Orca does not own.

### Ready mode track

Use a **discrete ordinal notch track**:

- Render one small notch per `availableEfforts`, in upstream order.
- Mark the exact explicit selected effort with a filled marker and its upstream `name` in the concise label.
- If there is no explicit selection and `defaultEffortId` matches a listed effort, mark it with an outlined default marker and label it `Model default: <name>`.
- If selection and default differ, selected is primary and default is a secondary outline only. The label remains `Selected: <name>`.
- If `selected.effortId` is null and `defaultEffortId` is null or has no matching current effort, show `No explicit selection`; do not choose a notch or claim an effective effort.

The selected/default distinction is therefore shown directly in the compact text label and marker style. This avoids presenting a model default as a user action. The presentation may state `Model default` because it is explicitly labelled as a default; it must not call it `Selected`.

### `off`, `unsupported`, `stale`, and `unknown`

- `off` is a valid ready catalog entry. It appears as the first or otherwise current ordered notch and is labelled using its upstream display name, typically `Off`.
- `unsupported` has no reasoning catalog and uses the unavailable icon/text above. It does not render an `Off` notch.
- `stale` retains no false selected position. The track may show the current catalog in a muted state plus an unmatched marker, with the warning label. It never chooses default, nearest, first, or last as a fallback.
- `unknown` hides the catalog and selected/default marker because their validity cannot be established. It uses the distinct uncertainty text rather than a generic `?` alone.

## Layout and Coexistence

### Selected surface

R3.2 should use the existing, rc.6-evidenced standard slot:

```text
conversation.input.left
```

This is the only slot currently verified in Orca's rc.6 Web client through the Token Monitor. The companion should register separately at an order after the Token Monitor (`orca-token-monitor` currently uses `-20`), so neither package owns the other. The exact R3.2 order must be checked against the rc.6 slot contract during implementation.

Rejected for this MVP:

- `conversation.input.right`, because Liang's development effort control already uses it;
- a fixed corner overlay, header-like surface, or WinForms overlay, because none has equivalent Orca rc.6 slot evidence and overlays create obstruction risk;
- an input overlay, because it would compete with the textarea, send affordance, keyboard focus, and assistive navigation.

### Token Monitor coexistence

```text
Token Monitor = telemetry and numeric current-session information
Orca companion = Activity and reasoning-mode presentation
```

The companion does not display Input, Output, Cache Read, TPS, Reasoning token, or Estimated state. **R3 MVP does not consume `DshMetricsSnapshot`.** The two packages share only the active DSH session identity indirectly through their independent reviewed selectors/projections.

### Liang development-build coexistence

- The companion uses the left slot; Liang's slider remains in the right slot.
- It must not read Liang frame, level, CSS variables, localStorage, presenter, assets, or settings.
- It uses no fixed backdrop, no full-viewport layer, and no positive z-index overlay. Its normal slot layout follows DSH document flow.
- It must remain legible without trying to recolor or override Liang's theme/background. If contrast is insufficient in validation, the companion may use its own bounded surface border/background token, not a Liang-specific selector.
- R3.2 E2E must verify no overlap, no pointer interception, and no competing high-frequency motion.

## Placeholder Asset Policy

The first renderer uses a self-contained, Orca-owned abstract glyph: a small inline SVG or CSS geometry formed from a body ellipse, fin/tail shapes, and a mode-track anchor. It is an **orca-inspired abstract status glyph**, not character artwork, a copied icon, a portrait, or a derivative of Liang assets.

- No asset CDN, remote fetch, bundled external sprite, character artwork, or formal mascot asset enters R3.2 by default.
- The exact inline path/CSS must be authored in this repository and reviewed as Orca-owned code.
- A future figurative character or artwork requires traceable author, code/media license, redistribution approval, attribution/NOTICE treatment, and a public-release review. The unresolved Liang assets cannot be reused as that source.

## Motion and Reduced Motion

### Normal motion

| Activity | Bounded motion |
| --- | --- |
| idle | 4–6 second low-amplitude breathing cycle |
| waiting | one slow anticipation pulse, then static wait |
| thinking | 2–3 second deliberate, low-amplitude orbit or fin movement |
| tool | one short utility pulse, then hold |
| review | one gentle settling/outward response motion |
| done | a single confirmation motion, then still |
| failed | no loop; stable alert indicator |

Motion is decorative reinforcement only. Labels, posture/icon, and the ordinal track carry the state when animation is unavailable.

### `prefers-reduced-motion: reduce`

Under reduced motion:

- disable loops, orbit, breathing, transition transforms, and attention pulses;
- preserve each state with its label plus a stable posture/icon;
- replace cross-fades with immediate state changes or a minimal opacity change that does not repeat;
- keep selected/default/stale/unavailable marker shapes distinct;
- never use timing or animation frequency as the only Activity signal.

## Accessibility and Responsive Rules

The companion is read-only, so its root should use `pointer-events: none` **provided that it contains no interactive descendants**. This prevents accidental interception of textarea, send, Workspace Write, Token Monitor, and Liang controls. If future work makes any element interactive, that change is a write-path/UI review and must remove the blanket rule for the focusable control, add an accessible name, focus behavior, and keyboard support.

Other requirements:

- meet normal text/icon contrast against the current DSH surface; use icon/shape/text in addition to color;
- no keyboard focus target in R3.2;
- scale without clipping at browser zoom;
- announce no live ARIA status by default. Rapid activity updates would be noisy; a future assistive announcement policy needs separate review.

| Environment | Rule |
| --- | --- |
| Wide desktop | Show glyph, Activity label, and compact ordinal mode track. |
| Narrow conversation width | First remove nonessential mode description; retain glyph plus Activity label. If the left slot would wrap into or reduce input controls, hide the companion rather than overlay it. A provisional implementation validation threshold is below roughly 760 CSS px available conversation width, subject to measured rc.6 layout evidence. |
| Small-height window | Keep the companion in normal slot flow; do not float it over the composer. If the composer area is compacted, use the same hidden state as narrow width. |

The numerical threshold is a design hypothesis, not a verified rc.6 layout measurement. R3.2 must validate it under WinForms WebView2 and ordinary `dsh web` rather than treating it as a fixed contract.

## State Matrix

The renderer applies the following rule matrix rather than expanding every Activity × availability pair.

| Activity | Intensity availability | Visual result |
| --- | --- | --- |
| Any | `no-session` | Hide; clear all local hold/transition state. |
| Any | `loading` | Activity glyph/label remains usable; muted `Preparing reasoning modes` track, no selection inference. |
| `thinking` | `ready` | Deliberate thinking motion + explicit selected/default ordinal marker. |
| `tool` | `ready` | Tool badge/pulse + unchanged static ordinal marker. |
| `failed` | `ready` | Stopped alert posture + selected/default marker; no looping animation. |
| `idle` | `unsupported` | Resting glyph + unavailable icon/text; never show `Off`. |
| `thinking` | `stale` | Thinking motion + warning marker/text; no hidden fallback. |
| Any | `unknown` | Activity remains visible with a neutral uncertainty treatment; catalog hidden. |

Activity terminal/error priority still applies inside a row. For example, `failed + stale` shows the failed alert as primary and a small stale reasoning warning as secondary; it does not convert either condition into the other.

## Transition and Error Isolation Rules

| Trigger | Required visual behavior |
| --- | --- |
| Activity transition | Apply priority/debounce/hold rules locally; never mutate adapter state. |
| Intensity update | Update only the static mode track/availability treatment; do not restart Activity motion unless availability changes the rendered component structure. |
| Session A → B | Cancel A's visual hold/animation state before subscribing/rendering B. Render B from its own current snapshots only. |
| Model switch | Re-render from the new `OrcaIntensityStateV0`; do not retain an old notch/default marker. |
| Renderer mount | Start with the current selector/projection snapshots; do not animate a fabricated prior state. |
| Client refresh | Re-derive all content from DSH state; no persisted presentation cache. |
| Renderer exception | Fail closed: remove/hide only the companion and clean up its selector/slot/style resources. Conversation, Token Monitor, composer, and Liang must remain functional. |

The implementation must scope all style selectors to the companion root and ensure unmount/dispose removes subscriptions, slot registration effects, and injected style. It must never throw from an individual malformed presentation snapshot into the surrounding conversation tree.

## R3.2 Recommended Implementation Shape

One small DSH Web client package is sufficient:

```text
dsh-client-orca-presentation
```

Recommended responsibility boundary:

```text
DSH upstream state
  -> existing Metrics / Activity projections and Intensity selector
  -> dsh-client-orca-presentation read-only component
  -> scoped CSS / inline Orca-owned SVG geometry
```

The package may inject the existing client services necessary to read Activity projections, subscribe to the existing `OrcaIntensityStateV0` selector, and register the verified slot. It must not introduce a generic animation framework, theme engine, character framework, asset manager, host projection, SessionEvent reducer, new persistence layer, or DSH RPC/write service.

## R3.2 Acceptance Criteria

Before any R3.2 implementation can close, evidence must show:

1. standard rc.6 `dsh web` bundle/load and actual companion render PASS;
2. Orca WinForms WebView2 visual E2E PASS;
3. every Activity state renders with the specified label/posture treatment;
4. `ready`, `loading`, `unsupported`, `stale`, `unknown`, and `no-session` Intensity treatments render correctly;
5. selected/default distinction is truthful; `off` remains distinct from unsupported;
6. Session A/B switching has no old-session animation, marker, or label leakage;
7. Token Monitor coexistence PASS, with no duplicated telemetry;
8. Liang development-build coexistence PASS, with no overlap, pointer interception, or Liang coupling;
9. reduced-motion behavior PASS;
10. wide, narrow, small-height, browser zoom, and input/send-control non-obstruction checks PASS;
11. unmount/dispose cleanup PASS, including no remaining selector/store subscriptions or style/slot residue;
12. all placeholder geometry is Orca-owned and carries no external asset/CDN dependency.

## Non-goals

- `session.selectModel`, reasoning-effort writes, drag-to-apply, or any effort control;
- shared preview state, recommendation, auto-apply, routing, or model policy;
- metrics/dashboard expansion, charts, historical analytics, cost information, or a second Token Monitor;
- generic theme, animation, character, Pet, or asset-management framework;
- Liang modifications, Liang asset reuse, or a formal character/portrait release;
- DSH upgrade, DSH core change, profile migration redesign, installer change, or WinForms overlay;
- public release approval.

## Open Design Validation Questions

- The `conversation.input.left` compact layout and provisional narrow-width threshold require actual rc.6 visual validation; the slot API is verified, its final spatial budget is not.
- The exact line/icon contrast under every current DSH/Liang development appearance requires visual E2E; the design deliberately avoids Liang-specific style coupling.
- Whether `Failed` should remain visible across a host-provided later `idle` state needs product review only if the current Activity contract proves that transition too short for users to perceive. R3.2 must initially follow the adapter snapshot plus the bounded local hold above.
