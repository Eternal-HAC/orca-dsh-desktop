window.__ModuleLoader__.load({
  id: "dsh-client-orca-presentation",
  factory: (require) => {
    const React = require("react")

    const ACTIVITY_LABELS = Object.freeze({
      idle: "Idle",
      waiting: "Waiting",
      thinking: "Thinking",
      tool: "Using tool",
      review: "Responding",
      done: "Done",
      failed: "Failed",
    })
    const EMPTY_ACTIVITY = Object.freeze({ state: "idle" })
    const ABSENT_FACE = Object.freeze({ getSnapshot: () => undefined, subscribe: () => () => {} })
    const WAITING_DELAY_MS = 250
    const TOOL_HOLD_MS = 400
    const DONE_HOLD_MS = 1200
    const STYLE = `
.orca-status-companion{display:inline-flex;flex:0 0 auto;max-width:100%;pointer-events:none;color:var(--dsw-alias-fg-base,var(--dsw-alias-fg-l1,#24304a));font-size:11px;line-height:1.15}
.orca-status-companion__inner{display:inline-flex;align-items:center;gap:6px;min-width:0;padding:4px 7px;border:1px solid var(--dsw-alias-border-l1,rgba(80,95,125,.28));border-radius:999px;background:var(--dsw-alias-bg-l2,rgba(255,255,255,.78));box-shadow:0 1px 2px rgba(12,22,42,.08)}
.orca-status-companion__glyph{position:relative;display:inline-flex;width:22px;height:16px;flex:0 0 auto;align-items:center;justify-content:center;transform-origin:center}
.orca-status-companion__glyph svg{width:22px;height:16px;overflow:visible;fill:none;stroke:currentColor;stroke-width:2.5;stroke-linecap:round;stroke-linejoin:round}
.orca-status-companion__body{fill:currentColor;opacity:.18}.orca-status-companion__fin{fill:currentColor;opacity:.55}.orca-status-companion__tail{opacity:.82}
.orca-status-companion__badge{position:absolute;right:-5px;top:-7px;display:grid;width:11px;height:11px;place-items:center;border-radius:99px;background:var(--dsw-alias-bg-l1,#fff);border:1px solid currentColor;font-size:8px;font-weight:800;line-height:1}
.orca-status-companion__activity,.orca-status-companion__mode-label{overflow:hidden;text-overflow:ellipsis;white-space:nowrap}.orca-status-companion__activity{font-weight:650}.orca-status-companion__mode{display:inline-flex;align-items:center;gap:4px;min-width:0;color:var(--dsw-alias-fg-l2,#54627a)}
.orca-status-companion__track{display:inline-flex;gap:3px;align-items:center;flex:0 0 auto}.orca-status-companion__track i{display:block;width:5px;height:5px;border:1px solid currentColor;border-radius:50%;opacity:.48}.orca-status-companion__track i[data-default="true"]{width:7px;height:7px;opacity:.85}.orca-status-companion__track i[data-selected="true"]{background:currentColor;opacity:1}
.orca-status-companion__mode-icon{display:grid;width:11px;height:11px;place-items:center;border:1px solid currentColor;border-radius:50%;font-size:8px;line-height:1}.orca-status-companion[data-availability="stale"] .orca-status-companion__mode{color:var(--dsw-alias-warning,var(--dsw-alias-fg-l2,#8d5b00))}.orca-status-companion[data-activity="failed"]{color:var(--dsw-alias-danger,#a33b46)}
.orca-status-companion[data-activity="idle"] .orca-status-companion__glyph{animation:orca-status-breathe 5s ease-in-out infinite}.orca-status-companion[data-activity="waiting"] .orca-status-companion__glyph{animation:orca-status-wait 1.8s ease-out 1}.orca-status-companion[data-activity="thinking"] .orca-status-companion__glyph{animation:orca-status-think 2.4s ease-in-out infinite}.orca-status-companion[data-activity="tool"] .orca-status-companion__glyph{animation:orca-status-tool .55s ease-out 1}.orca-status-companion[data-activity="review"] .orca-status-companion__glyph{animation:orca-status-review 1.4s ease-in-out 1}.orca-status-companion[data-activity="done"] .orca-status-companion__glyph{animation:orca-status-done .45s ease-out 1}.orca-status-companion[data-activity="failed"] .orca-status-companion__glyph{animation:none}
.orca-status-companion[data-layout="compact"]{align-self:flex-start}.orca-status-companion[data-layout="compact"] .orca-status-companion__mode-label{display:none}.orca-status-companion[data-layout="hidden"]{display:none}
@keyframes orca-status-breathe{50%{transform:translateY(-1px) scale(1.025)}}@keyframes orca-status-wait{45%{transform:translateX(2px) scale(1.04)}}@keyframes orca-status-think{50%{transform:translateY(-1px) rotate(-4deg)}}@keyframes orca-status-tool{50%{transform:scale(1.11)}}@keyframes orca-status-review{50%{transform:translateX(1px) scale(1.035)}}@keyframes orca-status-done{50%{transform:scale(1.08)}}
@media (prefers-reduced-motion: reduce){.orca-status-companion,.orca-status-companion__glyph{transition:none!important;animation:none!important;transform:none!important}}
`

    function activityName(value) {
      return Object.prototype.hasOwnProperty.call(ACTIVITY_LABELS, value) ? value : "idle"
    }

    function useObservable(source, fallback) {
      return React.useSyncExternalStore(source.subscribe, source.getSnapshot, source.getSnapshot) ?? fallback
    }

    // This pure controller is presentation-local. It never changes the
    // ActivityAdapter snapshot, and its timers are owned by one component.
    function createActivitySmoother(onChange, timers = globalThis) {
      let displayed = "idle"
      let raw = "idle"
      let timeout = null
      let disposed = false

      const clear = () => {
        if (timeout !== null) timers.clearTimeout(timeout)
        timeout = null
      }
      const show = (next) => {
        if (displayed === next || disposed) return
        displayed = next
        onChange(next)
      }
      const scheduleDoneIdle = () => {
        clear()
        timeout = timers.setTimeout(() => {
          timeout = null
          if (raw === "done") show("idle")
        }, DONE_HOLD_MS)
      }

      return {
        update(value) {
          if (disposed) return
          const next = activityName(value)
          raw = next
          if (next === "failed") {
            clear()
            show("failed")
            return
          }
          if (next === "waiting" && displayed !== "waiting") {
            clear()
            timeout = timers.setTimeout(() => {
              timeout = null
              if (raw === "waiting") show("waiting")
            }, WAITING_DELAY_MS)
            return
          }
          if (displayed === "tool" && next !== "tool") {
            clear()
            timeout = timers.setTimeout(() => {
              timeout = null
              if (raw !== "failed") {
                show(raw)
                if (raw === "done") scheduleDoneIdle()
              }
            }, TOOL_HOLD_MS)
            return
          }
          clear()
          show(next)
          if (next === "done") scheduleDoneIdle()
        },
        dispose() {
          if (disposed) return
          disposed = true
          clear()
        },
      }
    }

    function useDisplayedActivity(activity, sessionId) {
      const [displayed, setDisplayed] = React.useState("idle")
      const current = React.useRef(null)

      React.useEffect(() => {
        const smoother = createActivitySmoother(setDisplayed)
        current.current = { sessionId, smoother }
        smoother.update(activityName(activity?.state))
        return () => {
          smoother.dispose()
          if (current.current?.sessionId === sessionId) current.current = null
        }
      }, [sessionId])

      React.useEffect(() => {
        if (current.current?.sessionId === sessionId) current.current.smoother.update(activityName(activity?.state))
      }, [activity?.state, sessionId])

      // A new session must never momentarily borrow an old session's done/tool hold.
      return current.current?.sessionId === sessionId ? displayed : "idle"
    }

    function useCompanionLayout(rootRef) {
      const [layout, setLayout] = React.useState("full")
      React.useEffect(() => {
        // DSH rc.6 wraps this slot in a display:contents bridge. That bridge has
        // a zero rect, so it cannot be the responsive measurement target.
        let element = rootRef.current?.parentElement
        let anchor = null
        let sawLayoutContainer = false
        while (element) {
          const style = getComputedStyle(element)
          const width = element.getBoundingClientRect().width
          // Keep the whole contiguous composer region, rather than the narrow
          // tools rail shared by sibling slot entries (for example Token Monitor).
          if (style.display === "contents" && sawLayoutContainer) break
          if (style.display !== "contents" && width > 0) {
            sawLayoutContainer = true
            if (anchor === null || width >= anchor.getBoundingClientRect().width) anchor = element
          }
          element = element.parentElement
        }
        if (!anchor || typeof ResizeObserver !== "function") return undefined
        const update = () => {
          const width = anchor.getBoundingClientRect().width
          setLayout(width < 360 ? "hidden" : width < 520 ? "compact" : "full")
        }
        const observer = new ResizeObserver(update)
        observer.observe(anchor)
        update()
        return () => observer.disconnect()
      }, [])
      return layout
    }

    function intensityPresentation(state) {
      const availability = typeof state?.availability === "string" ? state.availability : "unknown"
      if (availability !== "ready") {
        const labels = {
          loading: "Preparing reasoning modes",
          unsupported: "No reasoning modes for this model",
          stale: "Reasoning selection needs refresh",
          unknown: "Reasoning state unavailable",
        }
        return { availability, label: labels[availability] ?? "Reasoning state unavailable", efforts: [], selectedId: null, defaultId: null }
      }
      const efforts = Array.isArray(state.availableEfforts) ? state.availableEfforts : []
      const selectedId = typeof state.selected?.effortId === "string" ? state.selected.effortId : null
      const defaultId = typeof state.defaultEffortId === "string" ? state.defaultEffortId : null
      const selected = selectedId === null ? null : efforts.find((item) => item?.effortId === selectedId) ?? null
      const fallback = selectedId === null && defaultId !== null ? efforts.find((item) => item?.effortId === defaultId) ?? null : null
      if (selected) return { availability, label: `Selected: ${selected.name}`, efforts, selectedId, defaultId }
      if (fallback) return { availability, label: `Model default: ${fallback.name}`, efforts, selectedId: null, defaultId }
      return { availability, label: "No explicit selection", efforts, selectedId: null, defaultId: null }
    }

    function Glyph({ activity }) {
      const alert = activity === "failed"
      const badge = activity === "tool" ? "⌁" : activity === "done" ? "✓" : alert ? "!" : null
      return React.createElement("span", { className: "orca-status-companion__glyph", "aria-hidden": "true" },
        React.createElement("svg", { viewBox: "0 0 48 32", focusable: "false" },
          React.createElement("path", { className: "orca-status-companion__body", d: "M5 17c5-9 17-13 30-9 5 2 8 6 8 9-5-2-9-1-13 2-6 6-16 6-25-2Z" }),
          React.createElement("path", { className: "orca-status-companion__fin", d: "M22 10 26 2l4 10" }),
          React.createElement("path", { className: "orca-status-companion__tail", d: "M8 17 2 11m6 6-6 5" })
        ),
        badge === null ? null : React.createElement("span", { className: "orca-status-companion__badge" }, badge)
      )
    }

    function StatusBody({ sessionId, activityFace, directoryFace, mapper, unavailable }) {
      const rootRef = React.useRef(null)
      const activity = useObservable(activityFace, EMPTY_ACTIVITY)
      const directoryState = directoryFace === null ? null : useObservable(directoryFace, null)
      const intensity = unavailable
        ? { availability: "unknown", sessionId, availableEfforts: [], selected: { effortId: null, normalizedPosition: null }, defaultEffortId: null }
        : mapper({ sessionId, directoryState })
      const displayedActivity = useDisplayedActivity(activity, sessionId)
      const mode = intensityPresentation(intensity)
      const layout = useCompanionLayout(rootRef)
      if (intensity?.availability === "no-session") return null
      const description = `${ACTIVITY_LABELS[displayedActivity]} — ${mode.label}`
      return React.createElement("section", {
        ref: rootRef,
        className: "orca-status-companion",
        "data-activity": displayedActivity,
        "data-availability": mode.availability,
        "data-layout": layout,
        "aria-label": `Orca status: ${description}`,
      },
        React.createElement("div", { className: "orca-status-companion__inner" },
          React.createElement(Glyph, { activity: displayedActivity }),
          React.createElement("span", { className: "orca-status-companion__activity" }, ACTIVITY_LABELS[displayedActivity]),
          React.createElement("span", { className: "orca-status-companion__mode", "data-mode": mode.availability },
            mode.availability === "ready"
              ? React.createElement("span", { className: "orca-status-companion__track", "aria-hidden": "true" }, mode.efforts.map((effort) => React.createElement("i", {
                key: effort.effortId,
                "data-selected": effort.effortId === mode.selectedId ? "true" : undefined,
                "data-default": effort.effortId === mode.defaultId ? "true" : undefined,
              })))
              : React.createElement("span", { className: "orca-status-companion__mode-icon", "aria-hidden": "true" }, mode.availability === "stale" ? "!" : mode.availability === "unknown" ? "?" : "·"),
            React.createElement("span", { className: "orca-status-companion__mode-label" }, mode.label)
          )
        )
      )
    }

    class StatusBoundary extends React.Component {
      constructor(props) {
        super(props)
        this.state = { failed: false }
      }
      static getDerivedStateFromError() {
        return { failed: true }
      }
      render() {
        return this.state.failed ? null : this.props.children
      }
    }

    function StatusCompanion(props) {
      return React.createElement(StatusBoundary, null, React.createElement(StatusBody, props))
    }

    function install(ctx, mapper) {
      return ctx.slots.inject("conversation.input.left", () => ctx.slots.register({
        name: "conversation.input.left",
        id: "orca-status-companion",
        order: -10,
        inject: (sessionId) => {
          const activityFace = ctx.sessions.binding(sessionId)?.session?.projections?.faceOf("orcaDshActivity") ?? ABSENT_FACE
          let directoryFace = null
          let unavailable = false
          try {
            if (ctx.sessions.subagentAddress(sessionId) !== undefined) {
              unavailable = true
            } else {
              const directory = ctx.modelDirectories.directoryFor(sessionId)
              directoryFace = directory.store
              if (directory.store.getSnapshot()?.status === "idle") directory.load().catch(() => {})
            }
          } catch {
            unavailable = true
          }
          return { sessionId, activityFace, directoryFace, mapper, unavailable }
        },
      }, StatusCompanion))
    }

    function apply(ctx) {
      ctx.effect(() => {
        let disposed = false
        let uninstall = () => {}
        const style = typeof document === "undefined" ? null : document.createElement("style")
        if (style !== null) {
          style.textContent = STYLE
          document.head.append(style)
        }
        // The mapper is loaded through DSH's client-module graph. This avoids
        // a forbidden cross-plugin value import and reuses the R2 pure API.
        ctx.modules.import("dsh-client-orca-intensity-state").then((intensityApi) => {
          if (disposed || typeof intensityApi?.mapOrcaIntensityState !== "function") return
          uninstall = install(ctx, intensityApi.mapOrcaIntensityState)
        }).catch(() => {})
        return () => {
          disposed = true
          uninstall()
          style?.remove()
        }
      })
    }

    return {
      inject: ["slots", "sessions", "modelDirectories", "modules"],
      apply,
      activityName,
      intensityPresentation,
      createActivitySmoother,
    }
  },
})
