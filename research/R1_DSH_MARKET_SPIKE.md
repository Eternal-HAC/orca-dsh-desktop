# R1.1 dsh-market Isolated Integration Spike

状态：Completed spike, decision `DEFER`

日期：2026-08-20

范围：隔离测试；未修改 Orca production profile、migration、runtime 或 installer

## Exact Baseline

| Item | Exact value |
| --- | --- |
| Repository | `https://github.com/dsh-market/dsh-market` |
| Package | `dshmarket` |
| Release | `v1.16.0`, stable GitHub release |
| Commit | `fa5200829cbcc2a0cb4b5e0d2199f74a26f928fc` |
| Release time | `2026-08-20T10:40:02Z` |
| npm tarball SHA-1 | `73e3b18582fe79e1c675db808554f12b88efb512` |
| npm tarball integrity | `sha512-WuHVUQzzECcK0gWdf0Q84KVvKNYNLTbF/GEh2TpBZEeekEI9hbZlqRu3kDwfVDciRgb49GtD0ost1sn45BbfMQ==` |
| Node | Orca bundled `v24.14.0` |
| DSH | Orca pinned `0.1.0-rc.6` |
| Test DSH_HOME | `%TEMP%\orcadsh-r11-market-home-44a209dbf1e74dc5b5e0851aa6241d9a` |
| Profile origin | Copy of current Orca `profile-seed/profiles/web`; no credentials or sessions copied |

The repository was created on 2026-08-14. The audited release was published six days later after a rapid sequence of releases. This is maintenance-risk evidence, not a claim that the project is abandoned or unsafe.

## License and attribution

- Repository root `LICENSE` is MIT, copyright 2026 fkysly and dsh-market contributors.
- `package.json.license` is `MIT`.
- The published `dshmarket-1.16.0.tgz` contains the same `LICENSE` and no `NOTICE`.
- npm `gitHead` matches the audited tag commit and the downloaded tarball hashes match npm metadata.
- The published tarball does not contain the repository `assets/` directory. It contains source, compiled host/client code, README files, the Cordis patch and LICENSE.
- No GPL, AGPL or other copyleft license was found in the direct package. This spike did not complete a transitive license audit of `js-yaml`, `undici`, Cordis or their dependency trees.
- Repository images and other non-published assets do not have separate asset-license evidence in the audited tree. They are outside the npm package tested here and must be audited if a future distribution copies them.

Conclusion: the direct `dshmarket@1.16.0` package has sufficient MIT evidence for isolated evaluation. This is not a complete legal-clearance statement for a future Orca bundle.

## Architecture

`dshmarket` is a combined DSH Host and Web Client plugin.

Host side:

- Cordis entry `dsh-market` inserts `dshmarket` through `cordis.patch.yml`.
- Hard injects `webServer` and `loader`.
- Reads optional `agents` to block package mutations while agents are running. Without that service mutations remain enabled.
- Reads optional `desktopProfiles`; if present, it additionally injects `desktopPnpm` and delegates package operations to that desktop contract.
- In ordinary `dsh web`, it resolves the active profile from config or `--profile`, mounts its own routes, and invokes the same DSH CLI that launched the host.
- `@deepseek-ai/dsh-settings` is an optional peer. rc.6 has no settings service, so the host settings namespace and rc.7 plugin card are skipped without preventing the main Market section from loading.

Web client side:

- Hard injects `slots`, `locale` and `theme`.
- Registers the main UI in `settings.section`.
- Registers a post-operation component in `shell.overlay`.
- Conditionally injects rc.7 `settingsScope` and registers `settings.plugin.item` only when available.
- Uses DSH client injection metadata for connection, runtime, locale, settings and theme services.

There is no WinForms-specific dependency. Ordinary rc.6 `dsh web` supplies the capabilities needed for the core Market UI and host routes.

## Host routes

The plugin mounts `/dsh-market/*` routes for registry, installed state, compatibility checks, status, logs, updates, install, uninstall, toggle, bundle order, groups, themes, backup/restore, WebDAV/Gist, pnpm setup, build-script approval, cancellation, rollback, self-update/removal and restart.

Mutating routes use same-origin checks and a shared in-process mutation lock. Package operations expose progress, capture bounded stdout/stderr, support cancellation and use a 15-minute default timeout. Windows cancellation uses `taskkill /T /F` for the spawned operation tree.

## Installation flow

For ordinary `dsh web` the flow is:

1. Fetch the curated catalog from `https://awesome-dsh-plugin.com/plugins.json` or `DSHM_REGISTRY_URL`.
2. Accept install targets only for entries resolved from that catalog.
3. Prefer the catalog's npm package name. Fall back to `github:owner/repo` or `github:owner/repo#path:/subpath`.
4. Spawn the same CLI invocation as `dsh plugin --profile <profile> add <target>`.
5. DSH delegates dependency resolution and profile reconciliation to pnpm.
6. Validate the installed manifest and loadable entry, reject duplicate loader-entry IDs, update the durable bundle list, then hot-mount simple patch shapes or request restart.

Uninstall invokes `dsh plugin --profile <profile> remove <name>`, removes its durable bundle row, and unmounts a live simple plugin where possible.

The Market does not run npm directly for package mutations. It requires `pnpm` on the child-process PATH. Its one-click pnpm preparation first runs `corepack enable pnpm`, then falls back to `npm install -g pnpm`.

## Files modified by Market

Observed or source-confirmed profile writes include:

- `profiles/web/package.json`: dependencies and `dsh.profile.bundles`.
- `profiles/web/pnpm-lock.yaml`: full dependency graph; it remained byte-different after fixture removal even though the fixture no longer appeared in the lockfile.
- `profiles/web/pnpm-workspace.yaml`: release-age exceptions and, after explicit approval, `allowBuilds`.
- `profiles/web/node_modules/`: package links, `.pnpm`, `.modules.yaml`, and potentially `.ignored` when pnpm takes over files installed by another package-manager layout.
- `profiles/web/cordis.patch.yml`: enable/disable and other Market-owned patch choices.
- `profiles/web/.dsh-market/state.json`: disable/group/channel state. Temporary `hot-*.yml` files are cleaned at host boot.

The first `dshmarket@1.16.0` add against the copied Orca seed moved the pre-existing Liang directory to `node_modules/.ignored` because it had been installed by a different package-manager layout, then downloaded/reinstalled Liang. The Orca adapter and Token Monitor directories remained present. This demonstrates that an add/remove operation replays the profile dependency graph and is not an isolated single-directory write.

The tested fixture lifecycle restored `package.json`, `pnpm-workspace.yaml` and `cordis.patch.yml` to their pre-fixture hashes. `pnpm-lock.yaml` changed. The fixture dependency, bundle row, node_modules link and live marker were removed. A test-only session sentinel and all four existing package directories remained.

## Rollback and failure handling

- Failed adds restore the raw manifest dependency snapshot. The source explicitly leaves the lockfile for pnpm to reconcile later.
- Broken or unloadable packages are removed or reverted to avoid a known next-boot failure.
- Update rollback can restore a previous npm or Git build and reinstall the dependency graph.
- Compatibility risks may produce a short-lived rollback token exposed through `/dsh-market/rollback`.
- Backup/restore is configuration-oriented and excludes `node_modules`, `.dsh-market`, `.git` and `pnpm-lock.yaml`.
- There is no transactional filesystem rollback covering the entire profile and pnpm store. A failed multi-plugin replacement can leave earlier removals applied, which the client source explicitly warns about.

## Compatibility matrix

| Seam | Result | Evidence |
| --- | --- | --- |
| DSH profile/plugin add/remove API | PASS | rc.6 added Market and completed fixture add/remove using the real CLI path. |
| Cordis bundle manifest and patch | PASS | Market and fixture loaded through normal bundle reconciliation. |
| Host `webServer` + `loader` inject | PASS | `/dsh-market/status`, registry and mutation routes served on rc.6. |
| Client loader and `./client` export | PASS | Browser rendered the Market section and version `v1.16.0`. |
| `settings.section` slot | PASS | Market appeared in rc.6 Settings navigation. |
| `shell.overlay` | PASS at module load | No loader/slot error; operation UI was not separately visually asserted. |
| rc.7 `settingsScope` / `settings.plugin.item` | NOT TESTED | Optional newer seam; absent on rc.6 and correctly skipped. |
| Optional `agents` mutation guard | PASS | rc.6 status reported `agentGuardAvailable: true`. |
| Ordinary CLI process execution | PASS WITH DEV TOOLCHAIN | Used bundled Node/DSH plus system pnpm `11.22.0`. |
| Orca bundled-runtime-only package operations | FAIL | With PATH limited to Orca Node + Windows system directories, status returned `pnpm: false`; setup could find neither npm nor corepack. |
| Desktop `desktopProfiles` / `desktopPnpm` | NOT TESTED | Current Orca host does not provide this contract. |
| Sessions/projections | N/A | Market does not depend on Orca State or session projections. |

No Orca compatibility shim was needed for Market UI, registry reading, package status or the tested lifecycle on rc.6. A future zero-system-dependency distribution would need an explicit private pnpm runtime strategy. That is distribution integration work, not a DSH semantic adapter.

## E2E results

| Scenario | Result | Evidence |
| --- | --- | --- |
| Isolated profile boot | PASS | Bundled Node 24.14.0 + DSH rc.6 served on loopback. |
| Market host load | PASS | `/dsh-market/status` reported version 1.16.0. |
| Market UI visible | PASS | Real browser showed Settings → 插件市场. |
| Catalog discovery/search data | PASS | Live catalog rendered and included version/source metadata. |
| Refresh recovery | PASS | Market heading, version and catalog returned after navigation refresh. |
| Browser/host errors | PASS WITH EXPECTED WARNINGS | No Market/module error observed; console warnings were connection-loss retries during deliberate host restarts. |
| Fixture install and hot load | PASS | Same-origin install returned 200 and fixture-owned liveness marker appeared. |
| Disable / re-enable | PASS | Marker disappeared and returned without touching neighbouring packages. |
| Host restart | PASS | Fixture loaded from durable bundle after restart. |
| Fixture remove | PASS | Dependency, bundle row, link and marker removed. |
| Post-remove profile boot | PASS | rc.6 host started again with Market and Orca bundle rows intact. |
| User-data boundary | PASS FOR TEST SENTINEL | Test session sentinel remained unchanged; no real credentials or sessions were used. |
| Existing real session behavior | NOT TESTED | Real user data was intentionally excluded. |
| Orca WinForms/WebView2 host | NOT TESTABLE SAFELY | `App.cs` fixes DSH_HOME to `%LOCALAPPDATA%\OrcaDSH`; this spike did not alter runtime or touch production user data. |
| Token Monitor/adapter rendering under WinForms | NOT TESTED | Package/bundle preservation and ordinary profile boot passed; reference-host rendering was not safely isolatable. |

## Upstream release hygiene findings

The audited tag is reproducible as a published tarball, but its repository development install is not clean:

1. `pnpm install --frozen-lockfile` failed because the committed `pnpm-lock.yaml` did not match `package.json`; six direct/dev specifiers were missing from the lockfile.
2. `pnpm install --no-frozen-lockfile` resolved dependencies but the package `prepare` build failed because `src/settings.ts` imports `@deepseek-ai/schemastery`, which was not declared/resolved in that workspace.

These findings do not invalidate the compiled npm tarball used by the runtime smoke. They reduce confidence in source reproducibility and maintenance stability for an immediate Orca adoption.

## Security and trust boundary

- An installed Host plugin runs inside the DSH Node process with the current Windows user's filesystem, network and process privileges unless the plugin itself constrains them.
- An installed Web client plugin runs same-origin with DSH and can call same-origin Market mutation routes. Same-origin protection blocks unrelated websites, but it is not isolation between installed plugins.
- Catalog membership limits source selection and npm name-squatting, but it is curation metadata rather than a code sandbox or cryptographic trust guarantee.
- npm tarballs are preferred; GitHub repository specs remain supported and can require Git.
- pnpm 10+ build scripts are blocked by default. The Market can add explicit `allowBuilds` entries after user approval; approved lifecycle/build scripts then execute with the user's process privileges.
- Install/update/remove replay the whole direct dependency graph. Network, registry and existing dependency failures can affect an unrelated requested operation.
- WebDAV and Gist features add external credential/data flows. The client avoids persisting the WebDAV password, and logs are memory-only with basic credential redaction, but any same-origin plugin shares the browser trust zone.

If Orca presents this Market, users may reasonably interpret catalog placement or Orca packaging as endorsement. Product copy must state that community plugins are third-party code, name their source/version/license, describe the privilege boundary, and require explicit confirmation before installation or build-script approval. Orca should not claim to certify every catalog entry.

## Offline and distribution impact

### Market itself

The exact npm tarball is prebuilt and can be bundled into a profile. Once present, the UI and installed-state view can boot offline, although catalog discovery and update metadata need network access unless a snapshot/source is supplied.

### Installing other plugins

User-initiated installs normally require network access to the catalog plus npm/GitHub sources. This is acceptable optional product behavior and does not have to make first launch network-dependent.

Current Orca distribution cannot perform those installs without external tooling. The private runtime contains `node.exe` but no npm, corepack or pnpm. The isolated test succeeded only because the development machine's `D:\nodejs\pnpm.ps1` was on PATH. In a bundled-runtime-only PATH, Market loaded but package operations were unavailable and its own setup route failed.

A future evaluation would need to pin and privately bundle pnpm, control its store/config/PATH, audit its licenses and package count, and verify that it never modifies system Node or global package state. Requiring users to install npm/pnpm/git would violate Orca's zero-setup distribution goal.

## Orca decision

```text
DEFER
```

Reason:

- Core ordinary `dsh web` architecture and rc.6 compatibility are proven.
- The direct package has clear MIT evidence and provides meaningful commodity value.
- No Orca State or DSH semantic shim is required.
- The project is only six days old at this snapshot and has a very high release cadence.
- The audited tag's source lockfile and build are not reproducible without manual intervention.
- Current Orca private runtime cannot execute plugin operations without a system pnpm; Market's automatic fallback assumes npm/corepack that Orca intentionally does not ship.
- The same-origin and full Node privilege model requires explicit product trust UX before distribution.

Distribution recommendation:

| Mode | Decision |
| --- | --- |
| Default bundle | No |
| Optional Orca bundle | No, while deferred |
| User-installable only | Manual/advanced use only; not an Orca-supported zero-setup path yet |
| Fork | No; no Orca-specific code difference currently justifies sync cost |

Re-open criteria:

1. Pin a later exact release with a clean frozen-lockfile source install and build.
2. Design and audit an Orca-private pnpm distribution path with no system/global mutation.
3. Re-run rc.6 or the then-current pinned DSH compatibility matrix and WinForms E2E through a safe DSH_HOME seam.
4. Define community-plugin trust/consent copy and attribution handling.
5. Re-audit direct and transitive licenses for the exact bundle candidate.
