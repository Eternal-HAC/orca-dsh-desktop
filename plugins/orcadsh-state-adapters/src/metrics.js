const isTokenCount = (value) => typeof value === 'number' && Number.isFinite(value) && value >= 0

const asTokenCount = (value) => isTokenCount(value) ? value : null

const eventTime = (event) => typeof event?.time === 'number' && Number.isFinite(event.time) ? event.time : null

export const initialMetricsState = () => ({
  inputTokens: null,
  outputTokens: null,
  reasoningTokens: null,
  cacheReadTokens: null,
  cacheWriteTokens: null,
  firstDeltaAt: null,
  lastDeltaAt: null,
  streamedCharacters: 0,
  hasProviderUsage: false,
})

/**
 * Returns the canonical rc.6 provider usage record. rc.6 writes finalized
 * message usage at event.data.usage; the nested alternatives keep this seam
 * tolerant of older plugin-generated events without changing the rc.6 path.
 */
export function usageFromEvent(event) {
  if (event?.type === 'assistant/chunk' && event.data?.chunk?.type === 'usage') return event.data.chunk.usage
  if (event?.type !== 'assistant/message') return undefined
  return event.data?.usage ?? event.data?.message?.data?.usage ?? event.data?.message?.usage
}

function deltaText(event) {
  if (event?.type !== 'assistant/chunk') return null
  const chunk = event.data?.chunk
  if (chunk?.type !== 'reasoning-delta' && chunk?.type !== 'text-delta') return null
  return typeof chunk.text === 'string' ? chunk.text : null
}

/** Pure one-event fold. Its state is bounded and JSON-serializable. */
export function reduceMetrics(state, event) {
  const usage = usageFromEvent(event)
  if (usage && typeof usage === 'object') {
    const inputTokens = asTokenCount(usage.inputTokens)
    const outputTokens = asTokenCount(usage.outputTokens)
    if (inputTokens === null || outputTokens === null) return state
    const at = eventTime(event)
    return {
      ...state,
      inputTokens,
      outputTokens,
      // rc.6's standard TokenUsage has no independent reasoning field. Accept
      // one only when a provider explicitly supplies it in a future extension.
      reasoningTokens: asTokenCount(usage.reasoningTokens),
      cacheReadTokens: asTokenCount(usage.cacheReadTokens),
      cacheWriteTokens: asTokenCount(usage.cacheWriteTokens),
      lastDeltaAt: at ?? state.lastDeltaAt,
      hasProviderUsage: true,
    }
  }

  const text = deltaText(event)
  if (text === null || text.length === 0) return state
  const at = eventTime(event)
  return {
    ...state,
    firstDeltaAt: state.firstDeltaAt ?? at,
    lastDeltaAt: at ?? state.lastDeltaAt,
    streamedCharacters: state.streamedCharacters + text.length,
  }
}

export function metricsSnapshot(state) {
  const outputTokens = state.hasProviderUsage
    ? state.outputTokens
    : state.streamedCharacters > 0 ? Math.ceil(state.streamedCharacters / 4) : null
  const start = state.firstDeltaAt
  const end = state.lastDeltaAt
  const durationSeconds = start !== null && end !== null && end > start ? (end - start) / 1000 : null
  return {
    inputTokens: state.inputTokens,
    outputTokens,
    reasoningTokens: state.reasoningTokens,
    cacheReadTokens: state.cacheReadTokens,
    cacheWriteTokens: state.cacheWriteTokens,
    tps: outputTokens !== null && durationSeconds !== null ? outputTokens / durationSeconds : null,
    // True only when this adapter exposed a character-based provisional output count.
    isEstimated: !state.hasProviderUsage && outputTokens !== null,
  }
}

export function createDshMetricsAdapter() {
  let state = initialMetricsState()
  return {
    consume(event) {
      state = reduceMetrics(state, event)
      return metricsSnapshot(state)
    },
    snapshot() {
      return metricsSnapshot(state)
    },
  }
}
