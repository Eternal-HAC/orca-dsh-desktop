# R3.2: Orca Read-only Status Companion Implementation

Date: 2026-08-23
Status: Implementation under review. No commit or push is authorized.

## Package and distribution

`plugins/dsh-client-orca-presentation@0.1.0` is an Orca-owned standard DSH Web client bundle. It contains `package.json`, `cordis.patch.yml`, `src/index.js`, `lib/client.js`, and `test/presentation-smoke.mjs`.

It registers `conversation.input.left` as `orca-status-companion` at order `-10`, after the existing Token Monitor at `-20`. Liang remains unmodified in `conversation.input.right`.

`build.ps1` copies the package into the existing profile seed; `App.cs` adds only this Orca-owned package to the existing `MigrateBundledWebPlugin()` allowlist; `Test-ReleaseBaseline.ps1` checks the package/bundle/client entry. No migration architecture changed.

## Dependencies and exact session scope

The manifest injects only rc.6 runtime, client modules, conversation UI, and model-selection UI packages. It has no Settings, Theme, Locale, Router, Metrics, host plugin, SessionEvent reducer, persistence, or animation-library dependency.

For a slot-provided `sessionId`, the renderer reads:

```text
ctx.sessions.binding(sessionId).session.projections.faceOf("orcaDshActivity")
ctx.modelDirectories.directoryFor(sessionId).store
existing mapOrcaIntensityState({ sessionId, directoryState })
```

It deliberately avoids the R2 global active-session selector inside a session-scoped slot. The existing mapper is loaded through `ctx.modules.import("dsh-client-orca-intensity-state")`, then receives the same exact slot session ID as Activity. This avoids A/B scope mismatch without changing the R2 contract or duplicating its mapper.

An addressed subagent session or unavailable directory becomes Intensity `unknown`, never a fabricated unsupported catalog.

## Behavior

The Compact Hybrid Status Companion renders an inline SVG/CSS abstract Orca glyph, the existing Activity label, and an Intensity track/label. It has no selection write, drag, preview, recommendation, auto apply, routing, Metric display, or polling.

- Activity labels: Idle, Waiting, Thinking, Using tool, Responding, Done, Failed. Unknown values safely render as Idle.
- Local-only smoothing: waiting 250 ms debounce, tool 400 ms hold, done 1200 ms hold, failed immediate override. Each component disposes its timers on unmount/session change.
- `ready`: one upstream-order notch per effort; Selected is filled and primary; default-only is outlined and explicitly labelled `Model default`.
- `loading`, `unsupported`, `stale`, and `unknown` use distinct text/icon treatments; `off` remains a normal ready effort.
- `no-session` returns no companion. `normalizedPosition` is never shown as a number or percentage.

## Layout, accessibility, and assets

All CSS is scoped below `.orca-status-companion`. The root has `pointer-events:none` and no interactive descendants. Motion is CSS-only and `prefers-reduced-motion: reduce` disables loops, pulses, transforms, and transitions while text/icon/notch distinctions remain.

A component-local ResizeObserver uses the outer contiguous layout region of the
rc.6 slot, rather than the zero-size display:contents bridge or the narrow
rail shared with Token Monitor:

```text
>= 520px full; 360px–519px compact; < 360px hidden
```

Real WebView2 testing found two layout defects and one compact coexistence
defect. The rc.6 display:contents bridge exposed a zero-width rect, the
Companion could flex-shrink to zero, and compact left/right slot content was
vertically centered into the same band as Liang. The production fixes skip the
zero-width bridge, keep the Companion as a non-shrinking flex item, and align
only the compact Companion to the top of its existing tools region. These are
E2E-found fixes, not speculative CSS changes. The 520/360 thresholds are
unchanged.

The glyph is repository-authored inline SVG only: no CDN, sprite, copied icon,
Liang asset, or character artwork.

`StatusBoundary` fails closed to `null`; module-import failure registers no slot. Effect cleanup removes the slot contribution and style; component cleanup removes timers and the observer.

## Testability seam and evidence boundary

The developer-only harness at tests/OrcaWebView2Harness/Program.cs is a
separate WinForms/WebView2 executable. scripts/Test-OrcaPresentationVisual.ps1
compiles it into a unique temporary directory, copies only staged
profile-seed/profiles into a new temporary DSH_HOME, starts pinned rc.6 on
loopback, and touches no user data. WebView2 receives a unique temporary
userDataFolder, never the production OrcaDSH WebView2 profile.

For a provider-free ordinary session, the script invokes rc.6 session.create
against the temporary host and preloads only the temporary WebView2
localStorage selection record. This is a browser-side selection fixture, not a
production fake-state mode. The mounted renderer still consumes the real rc.6
session, client modules, slots, projections, and model directory. rc.6 did not
auto-select a newly-created session in a fresh empty UI, so this fixture is
necessary for a real slot mount without credentials or provider traffic.

The harness dismisses the first-run rc.6 notice through its real Continue
button, probes DOM/computed layout with ExecuteScriptAsync, writes JSON and a
PNG screenshot to TEMP, then disposes WebView2. It does not prove production
App lifecycle, Setup installation, or existing-profile migration.

For compact evidence, the harness uses a 700px WebView and constrains the same
test-host responsive container selected by the production measurement
algorithm. Its measured width is 519px. This is a test-only host constraint;
it does not patch DSH or production renderer thresholds. The harness asserts
the actual compact mode, positive visible rects, and no pairwise overlap among
the Companion, Token Monitor, textarea/composer, send button, and Liang effort
control.

Production exclusion is structural: build.ps1 compiles only src/App.cs, copies
the four explicit Orca bundle sources to the seed, and stages only
dist/DeepSeekHarness; NSIS recursively packages that staging directory.
Neither tests/ nor Test-OrcaPresentationVisual.ps1 is a build, seed, or
installer input.

## Build JSON encoding compatibility

Windows PowerShell 5.1 writes a UTF-8 BOM for `Set-Content -Encoding utf8`,
while PowerShell 7 uses UTF-8 without BOM. The generated
`profile-seed/profiles/web/package.json` was therefore rejected by pinned DSH
rc.6 after a Windows PowerShell 5.1 build.

`build.ps1` now writes only that build-generated JSON path through
`System.IO.File.WriteAllText` with `System.Text.UTF8Encoding(false)`. The
existing ASCII build package metadata is already BOM-free; YAML and user
instructions are not JSON parse inputs and were not changed. The release
baseline test rejects `EF BB BF` at the start of the staged profile package.

Full builds pass under Windows PowerShell 5.1.26100.9168 and PowerShell 7.6.4.
For both outputs, the staged package begins with `7B 0D 0A`, bundled Node
JSON.parse passes, and pinned rc.6 starts from the resulting seed. This fixes
the known JSON BOM defect; it is not a claim that every future build tool or
script is cross-version compatible.

One pre-existing developer-test invocation seam remains: Windows PowerShell
5.1 evaluates the default `Test-ReleaseBaseline.ps1` ArtifactRoot expression
before `$PSScriptRoot` is available, so invoking that script without arguments
fails. Supplying the explicit built ArtifactRoot passes under both 5.1 and
7.6.4. This does not affect `build.ps1` or the artifact, and was not broadened
into an unrelated script-parameter refactor.

## Validation

| Check | Result | Evidence boundary |
| --- | --- | --- |
| Presentation VM smoke | PASS | Actual ModuleLoader entry; Activity/Intensity formatting, smoothing, exact session propagation, slot/order, cleanup, reduced-motion/pointer CSS, no Metrics/write syntax. |
| R2 intensity smoke | PASS | Existing mapper and selector regression. |
| State adapter smoke | PASS | Existing Metrics/Activity regression. |
| Full build | PASS | Windows PowerShell 5.1.26100.9168 and PowerShell 7.6.4 each produced the profile seed, WinForms executable, and NSIS Setup. |
| Release baseline / PowerShell AST | PASS | New bundle staged; no-BOM, DSH/Node/policy/license checks pass. |
| Ordinary rc.6 dsh web server | PASS | Fresh temporary DSH_HOME copied from seed served loopback port 3445. |
| Ordinary rc.6 real WebView2 DOM | PASS | Real WebView2 loaded all three Orca client resources, created/selected a provider-free temporary ordinary session, and mounted Companion/Token Monitor. No console/runtime errors were captured. |
| Wide layout, 1400px WebView | PASS | Companion flex/full, 199.1x26px; Token Monitor 80.5x125.8px; Liang effort control 124x28px; textarea 778x52px. Adjacent rects do not overlap. |
| Narrow layout, 320px WebView | PASS | Companion hidden/display:none, 0x0px; Token Monitor and composer remain rendered. |
| Compact layout, 700px WebView / 519px measured container | PASS | Companion 98.4x26px; Token Monitor 79.1x125.8px; composer/textarea 485x52px; send 34x34px; Liang 92x28px. Actual computed rects are visible and pairwise non-overlapping. |
| Liang development-build coexistence | PASS | Real Liang background and effort control rendered alongside Companion and Token Monitor. This does not change Liang's separate redistribution blocker. |
| Screenshot | PASS | Temporary manual-review PNG written by CoreWebView2.CapturePreviewAsync; it is not committed. |
| R3.2 WebView2 presentation E2E | PASS | Dedicated repository-only Microsoft WebView2 host, real ordinary rc.6 DOM/client slots, wide/compact/hidden layout, Token Monitor and Liang coexistence. |
| Production Orca App lifecycle | NOT TESTED | The dedicated harness is not src/App.cs and does not establish App startup/exit, Setup install, or existing-profile migration E2E. |

The final harness evidence root is
C:\Users\26703\AppData\Local\Temp\orca-r32-visual-final-verified; it contains
no real credentials or user sessions. It and earlier temporary test roots
remain local cleanup pending. The harness-owned DSH process and test port were
released after each run.

## Limits

The package does not establish 0.1.1-rc.2 runtime compatibility, R3 closure,
public-release approval, production App lifecycle, Setup installation,
existing-profile migration E2E, or any effort-control path.
