# R2.1: OrcaIntensityState v0 Contract Review

Date: 2026-08-23
Scope: Read-only contract design against Orca pinned DSH 0.1.0-rc.6 and Node 24.14.0. No adapter, runtime, Liang, profile seed, installer, pin, commit, or push is changed.

## Decision

Use an Orca-owned, per-ordinary-session client-side derived state. It preserves DSH raw effort IDs and exposes ordinal presentation positions. The field must be named normalizedPosition, not normalizedIntensity.

The reviewed U0 target 0.1.1-rc.2 adds low but provides no numeric intensity, recommendation, or visual scale. The recommended contract is PORTABLE across the rc.6 and target effort lists because it derives from the current ordered list.

## Source-of-Truth Audit

### Available efforts

For an ordinary session, the pinned rc.6 model-selection plugin owns a per-session ModelDirectory:

~~~
ctx.modelDirectories.directoryFor(sessionId)
  -> directory snapshot
  -> current ModelSelection plus provider groups
  -> exact current provider/model
  -> model.reasoning.efforts
~~~

The relevant upstream shape is:

~~~
LlmReasoningEffortInfo:
  id: ReasoningEffortId    opaque, stable, adapter-owned
  name: string             display metadata
  description?: string

LlmModelReasoningInfo:
  efforts: readonly LlmReasoningEffortInfo[]
  defaultEffort?: ReasoningEffortId
~~~

The array is documented by DSH as adapter-preferred display order. It supports ordinal display for one exact model. It does not prove equal semantic reasoning distance between entries.

### Default-effort provenance

`defaultEffortId` has an authoritative, consumer-visible source and remains in v0. In the pinned runtime the chain is:

~~~text
@deepseek-ai/dsh-llm-deepseek/lib/index.js
  -> exact resolved model reasoning.defaultEffort
@deepseek-ai/dsh-llm/lib/index.js
  -> validates that defaultEffort is one of reasoning.efforts
@deepseek-ai/dsh-client-connection/lib/client.js
  -> transports model.reasoning.defaultEffort as an optional string
@deepseek-ai/dsh-client-ui-model-selection/lib/client.js
  -> reads model.reasoning.defaultEffort for model choices and effective display
~~~

For DeepSeek rc.6, the adapter constructs this metadata from its resolved connection defaults: disabled thinking reports the explicit `off` default; otherwise the configured `off` or `max` is retained and an omitted adapter config reports `high`. This is adapter behavior materialized as current exact-model metadata, not an Orca inference or a generic first/middle-item fallback.

The DSH request validator separately resolves `requested reasoningEffort ?? reasoning.defaultEffort`. That effective request behavior must remain separate from the Host-reported explicit selection. On a model switch, the selector re-reads the matching exact model's `reasoning.defaultEffort` from the refreshed ModelDirectory.

### Selected effort and submission

The Host-reported ModelSelection is the only selection fact:

~~~
ModelSelection:
  provider: string
  model: string
  reasoningEffort?: ReasoningEffortId
~~~

The client reads it from ModelDirectoryState.current. It sends a complete ModelSelection through the ordinary-session session.selectModel RPC. The Host snapshots it at the next prompt-assembly boundary, then the provider request receives the same raw reasoningEffort ID. DSH persists selection only after a request header records a request that consumed it.

Orca therefore reads and derives state. It must not create a second selected-effort persistence store.

### Model switch behavior

The rc.6 plugin has one directory per session. It refetches after llm/adapters-updated and settings/document-updated, clears client-resident projections on connection reset, then reloads the Host-restored selection. The model UI applies an adapter default when its own model action does so; the composer may subsequently select any advertised effort.

R2.1 adds no switch persistence policy. Each snapshot is re-derived from current Host selection and current advertised metadata.

## Liang Isolation Audit

Liang owns a private presentation scale:

~~~
PREVIEW_MAX_FRAME = 240
MAX_LEVEL = 30
frameForEffort(index, count) = index / (count - 1) * 240
level = frame / 240 * 30
~~~

It reads the normal DSH directory state and matching model reasoning metadata. With binding enabled, it snaps the local frame to a nearest effort and invokes its injected selection boundary with provider, model, and target.id as reasoningEffort.

Liang writes only the raw DSH effort ID. Its frame and 0..30 level are local React/presenter state. The only persisted localStorage values are skin enabled and bind-effort preferences. No Orca-owned code outside Liang uses Liang frame, level, rank, or 0..30 mapping.

## Candidate Assessment

### Candidate A

~~~
effortId
normalizedIntensity
previewIntensity
source
~~~

Reject. It collapses selected, default, stale, unsupported, and loading into null values; it calls ordinal position intensity; it shares transient preview; and it omits available effort metadata.

### Candidate B

~~~
selected
recommended
previewIntensity
source
~~~

Reject for v0. Selected versus recommended must remain distinct as a product rule, yet R2 produces no recommendation. A nullable recommendation, preview, and general source label reserve behavior without a producer or consumer. It also retains the misleading intensity name.

## Final Contract

~~~
type OrcaIntensityAvailability =
  | 'no-session'
  | 'loading'
  | 'ready'
  | 'unsupported'
  | 'stale'
  | 'unknown'

interface OrcaIntensityEffort {
  effortId: string
  name: string
  description: string | null
  normalizedPosition: number
}

interface OrcaIntensitySelection {
  effortId: string | null
  normalizedPosition: number | null
}

interface OrcaIntensityStateV0 {
  availability: OrcaIntensityAvailability
  sessionId: string | null
  providerId: string | null
  modelId: string | null
  availableEfforts: readonly OrcaIntensityEffort[]
  selected: OrcaIntensitySelection
  defaultEffortId: string | null
}
~~~

Semantics:

- normalizedPosition is index divided by count minus one, or 0 for the sole advertised effort. It is finite and within 0..1. It is ordinal presentation position, never reasoning strength.
- selected.effortId is exactly Host ModelSelection.reasoningEffort. It does not fall back to defaultEffortId.
- defaultEffortId is the current exact model's authoritative `model.reasoning.defaultEffort`, transported through the ModelDirectory. It is not a user selection and never auto-writes DSH state.
- v0 has no recommended field. A future recommendation must be separately designed and never overwrite selected.
- v0 has no preview. Preview belongs to a client-local renderer, clears on refresh/session switch/rejected selection, is never a projection, and is not persisted.
- v0 has no source field. DSH cannot reliably disclose who selected a ModelSelection, while metadata origin is already fixed by the current directory.
- availableEfforts is required so controls/renderers can read count, labels, raw IDs, and ordinal positions without Orca inventing a second model catalog.
- Token Monitor and ActivityAdapter do not consume Intensity in v0.

## Off, Null, and Availability

off is an ordinary adapter-owned ReasoningEffortId. In the DeepSeek adapter, disabled thinking constrains the selectable effort to off. It is still distinct from unsupported metadata and from a null selected ID.

| Situation | Availability | Selected | Efforts | Meaning |
| --- | --- | --- | --- | --- |
| No active ordinary session | no-session | null / null | empty | No addressable consumer state |
| Directory loading | loading | unavailable | empty | Do not infer default or unsupported |
| Current model lacks reasoning metadata | unsupported | null / null | empty | No selectable reasoning metadata |
| Valid selected ID | ready | raw ID + position | nonempty | Normal state |
| Reasoning effort omitted | ready | null / null | nonempty | No explicit selection; default remains separate |
| Selected ID no longer in model list | stale | raw ID + null | current list | Never substitute an effort |
| Catalog or Host failure | unknown | only known raw values | empty unless current list is provably valid | No manufactured selection |

In the current rc.6 DeepSeek list, off is first and thus has normalizedPosition 0. That is a property of this adapter list only. Null never means off.

## Scope and Persistence

The state is per ordinary session and model-derived:

~~~
sessionId -> latest ModelDirectory -> selected provider/model -> snapshot
~~~

An active-session consumer selects one such snapshot. It is neither global nor forced to share Metrics/Activity scope. Addressed subagent sessions have no ordinary selection entry; R2.2 must document whether the selector returns unsupported or is unavailable for them.

DSH alone persists the complete ModelSelection after a consumed request. Orca persists none of the selected effort, positions, effort list, default, preview, or recommendation. All values re-derive after reload/reconnect.

## Model Switching

| Transition | v0 result |
| --- | --- |
| A off/high/max and high -> B off/low/high/max | Re-read B. If Host reports B/high, ready with position 2/3 |
| A selected ID disappears on B | stale, retain raw ID, position null, never write fallback |
| Switch to model without reasoning | unsupported, empty effort list |
| Switch back to A | Re-read Host and A metadata; no Orca cache restore |
| Directory row missing while route remains usable | unknown or stale; never synthesize a catalog row |

Unknown IDs such as eco, medium, ultra, adaptive, and vendor-x remain opaque. The mapper needs no switch statement over known IDs.

## Target Portability

| List | Result | Status |
| --- | --- | --- |
| rc.6 off/high/max | off = 0; high = 1/2; max = 1 | PORTABLE |
| target off/low/high/max | off = 0; low = 1/3; high = 2/3; max = 1 | PORTABLE |
| Unknown nonempty ordered list | preserve IDs and derive by index | PORTABLE |
| Missing reasoning metadata | unsupported | PORTABLE |
| Semantically ambiguous order | represent display order only | PORTABLE |

This is contract portability only. It is not target runtime compatibility PASS.

## Ownership and Layering

~~~
DSH Host ModelSelection plus adapter-owned model reasoning metadata
        -> Orca client-side pure selector/mapper
        -> OrcaIntensityStateV0 per-session snapshot
        -> future Orca renderer or effort-control UI
~~~

Forbidden paths:

~~~
Liang frame or level -> Orca state
Orca intensity adapter -> DSH routing policy
ActivityAdapter -> Intensity state
Token Monitor -> Intensity state
~~~

## R2.2 Implementation Recommendation

Implement a small Orca-owned client-side selector/mapper, as a separate client package or a clearly owned client module for the future effort-control surface. It should consume ctx.modelDirectories.directoryFor(sessionId), expose this pure derivation, and provide an active-session selector.

Do not create a host projection:

- available effort metadata and current selection are already client-directory state;
- a host projection duplicates ownership and introduces needless persistence/replay questions;
- existing state adapters should remain focused on SessionEvent-derived Metrics and Activity until a proven host consumer requires otherwise.

No implementation is authorized by this review.

## Acceptance Tests for R2.2

### Catalog and mapping

- absent reasoning metadata yields unsupported and empty efforts;
- one effort maps to 0;
- three ordered efforts map to 0, 0.5, 1;
- four ordered efforts map to 0, 1/3, 2/3, 1;
- unknown IDs preserve their raw IDs and names;
- every output position is finite and in 0..1.

### Selection and switching

- valid ID yields ready and matching position;
- null selected ID yields ready with independent defaultEffortId;
- stale ID retains raw ID with null position;
- loading/error never infer off;
- shared raw ID survives a model switch and recomputes on the new list;
- disappeared ID never auto-replaces;
- unsupported model clears presentation selection;
- switch back reads DSH truth, not Orca cache.

### User priority and lifecycle

- v0 exposes no recommendation or auto-apply path;
- a future recommendation fixture proves selected remains authoritative;
- a future control submits a full DSH ModelSelection, never a position;
- refresh/reconnect re-derives state;
- a later renderer preview disappears on refresh/session switch;
- active-session selection has no cross-session leakage.

## Canonical Documentation Follow-up

The R2.1 closure aligned ARCHITECTURE.md, ROADMAP.md, and DECISIONS.md with this reviewed v0 contract: they use normalizedPosition, keep the exact selected/default distinction, and state that preview, source, and recommendation are outside v0. The selected/recommended independence principle remains a long-term rule.

## Validation and Boundaries

- Static inspection used only bundled rc.6 packages and the development profile seed.
- U0 reviewed target static evidence was used for portability; target runtime was not installed or launched.
- No real credentials, sessions, API keys, provider calls, or user DSH_HOME were read.
- No production code, runtime, installer, profile seed, Liang package, pin, workflow, release policy, commit, or push was changed.
