window.__ModuleLoader__.load({
  id: "dsh-client-orca-intensity-state",
  factory: (require) => {
    const { createSnapshotStore } = require("@deepseek-ai/dsh-client-runtime/client")

    const EMPTY_SELECTION = Object.freeze({ effortId: null, normalizedPosition: null })
    const EMPTY_EFFORTS = Object.freeze([])

    function emptyState(availability, sessionId = null, providerId = null, modelId = null) {
      return {
        availability,
        sessionId,
        providerId,
        modelId,
        availableEfforts: EMPTY_EFFORTS,
        selected: EMPTY_SELECTION,
        defaultEffortId: null,
      }
    }

    function safeId(value) {
      return typeof value === "string" && value.length > 0 ? value : null
    }

    function modelFor(directoryState, providerId, modelId) {
      if (!Array.isArray(directoryState?.groups)) return null
      const group = directoryState.groups.find((candidate) => candidate?.id === providerId)
      if (group === undefined || !Array.isArray(group.models)) return null
      return group.models.find((candidate) => candidate?.id === modelId) ?? null
    }

    function mapEfforts(reasoning) {
      if (reasoning === null || typeof reasoning !== "object" || !Array.isArray(reasoning.efforts)) return null
      const count = reasoning.efforts.length
      if (count === 0) return null
      const efforts = []
      const seenIds = new Set()
      for (let index = 0; index < count; index += 1) {
        const effort = reasoning.efforts[index]
        if (effort === null || typeof effort !== "object" || safeId(effort.id) === null || typeof effort.name !== "string") return null
        if (effort.description !== undefined && typeof effort.description !== "string") return null
        if (seenIds.has(effort.id)) return null
        seenIds.add(effort.id)
        const normalizedPosition = count <= 1 ? 0 : index / (count - 1)
        if (!Number.isFinite(normalizedPosition) || normalizedPosition < 0 || normalizedPosition > 1) return null
        efforts.push({
          effortId: effort.id,
          name: effort.name,
          description: effort.description ?? null,
          normalizedPosition,
        })
      }
      return efforts
    }

    /**
     * Derive the frozen OrcaIntensityStateV0 from one ordinary session's
     * already-read ModelDirectory snapshot. This function has no I/O or writes.
     */
    function mapOrcaIntensityState(input) {
      const sessionId = safeId(input?.sessionId)
      if (sessionId === null) return emptyState("no-session")

      const directoryState = input?.directoryState
      if (directoryState === null || directoryState === undefined) return emptyState("loading", sessionId)
      if (typeof directoryState !== "object") return emptyState("unknown", sessionId)

      const current = directoryState.current
      const providerId = safeId(current?.provider)
      const modelId = safeId(current?.model)
      if (providerId === null || modelId === null) {
        if (directoryState.status === "idle" || directoryState.status === "loading" || directoryState.status === "selecting") {
          return emptyState("loading", sessionId)
        }
        return emptyState("unknown", sessionId)
      }

      const model = modelFor(directoryState, providerId, modelId)
      if (model === null) {
        if (directoryState.status === "idle" || directoryState.status === "loading" || directoryState.status === "selecting") {
          return emptyState("loading", sessionId, providerId, modelId)
        }
        return emptyState("unknown", sessionId, providerId, modelId)
      }
      if (model.reasoning === undefined) return emptyState("unsupported", sessionId, providerId, modelId)

      const efforts = mapEfforts(model.reasoning)
      if (efforts === null) return emptyState("unknown", sessionId, providerId, modelId)

      const rawSelected = current.reasoningEffort === undefined ? null : safeId(current.reasoningEffort)
      if (current.reasoningEffort !== undefined && rawSelected === null) return emptyState("unknown", sessionId, providerId, modelId)
      const defaultEffortId = model.reasoning.defaultEffort === undefined ? null : safeId(model.reasoning.defaultEffort)
      if (model.reasoning.defaultEffort !== undefined && defaultEffortId === null) return emptyState("unknown", sessionId, providerId, modelId)

      const selectedEffort = rawSelected === null ? null : efforts.find((effort) => effort.effortId === rawSelected) ?? null
      return {
        availability: rawSelected !== null && selectedEffort === null ? "stale" : "ready",
        sessionId,
        providerId,
        modelId,
        availableEfforts: efforts,
        selected: rawSelected === null
          ? EMPTY_SELECTION
          : { effortId: rawSelected, normalizedPosition: selectedEffort?.normalizedPosition ?? null },
        // Preserve even invalid upstream metadata verbatim. It is diagnostics
        // metadata, never an Orca fallback or a selected-effort replacement.
        defaultEffortId,
      }
    }

    /**
     * One active-session selector. It chooses the active ordinary session from
     * ctx.sessions.list, then subscribes to that session's shared ModelDirectory.
     * Consumers dispose it when their client scope unmounts.
     */
    function createActiveOrcaIntensityStateSelector(ctx) {
      const store = createSnapshotStore(mapOrcaIntensityState({ sessionId: null }))
      let directoryStop = () => {}
      let activeSessionId = null
      let hasBoundSession = false
      let disposed = false

      const publish = (directoryState) => {
        if (!disposed) store.set(mapOrcaIntensityState({ sessionId: activeSessionId, directoryState }))
      }

      const bindCurrentSession = () => {
        const sessionId = safeId(ctx?.sessions?.list?.getSnapshot?.()?.current)
        if (hasBoundSession && sessionId === activeSessionId) return
        hasBoundSession = true
        directoryStop()
        directoryStop = () => {}
        activeSessionId = sessionId
        if (sessionId === null) {
          publish(null)
          return
        }
        if (typeof ctx.sessions.subagentAddress !== "function" || typeof ctx?.modelDirectories?.directoryFor !== "function") {
          publish({ status: "error", current: null, groups: [] })
          return
        }
        // Addressed child sessions do not expose an ordinary ModelDirectory.
        if (ctx.sessions.subagentAddress(sessionId) !== undefined) {
          store.set(emptyState("unknown", sessionId))
          return
        }
        let directory
        try {
          directory = ctx.modelDirectories.directoryFor(sessionId)
        } catch {
          store.set(emptyState("unknown", sessionId))
          return
        }
        publish(directory.store.getSnapshot())
        directoryStop = directory.store.subscribe(() => publish(directory.store.getSnapshot()))
        // This is the existing DSH ModelDirectory refresh, once per binding.
        // Subsequent adapter/settings/reconnect refreshes belong to DSH itself.
        if (directory.store.getSnapshot().status === "idle") directory.load().catch(() => {})
      }

      const listStop = typeof ctx?.sessions?.list?.subscribe === "function"
        ? ctx.sessions.list.subscribe(bindCurrentSession)
        : () => {}
      bindCurrentSession()

      return {
        store,
        dispose() {
          if (disposed) return
          disposed = true
          listStop()
          directoryStop()
        },
      }
    }

    function apply() {}

    return {
      inject: ["sessions", "modelDirectories"],
      apply,
      mapOrcaIntensityState,
      createActiveOrcaIntensityStateSelector,
    }
  },
})
