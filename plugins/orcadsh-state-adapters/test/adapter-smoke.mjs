import assert from 'node:assert/strict'
import { reduceActivity } from '../src/activity.js'
import { initialMetricsState, metricsSnapshot, reduceMetrics } from '../src/metrics.js'

const sample = { type: 'assistant/chunk', time: 1_000, data: { turn: 1, step: 1, chunk: { type: 'reasoning-delta', index: 0, text: 'reasoning' } } }
let state = reduceMetrics(initialMetricsState(), sample)
state = reduceMetrics(state, { type: 'assistant/chunk', time: 2_000, data: { turn: 1, step: 1, chunk: { type: 'text-delta', index: 1, text: 'answer' } } })
assert.deepEqual(metricsSnapshot(state), {
  inputTokens: null, outputTokens: 4, reasoningTokens: null,
  cacheReadTokens: null, cacheWriteTokens: null, tps: 4, isEstimated: true,
})
state = reduceMetrics(state, { type: 'assistant/message', time: 3_000, data: { turn: 1, step: 1, usage: { inputTokens: 16, outputTokens: 13, cacheReadTokens: 5 } } })
assert.deepEqual(metricsSnapshot(state), {
  inputTokens: 16, outputTokens: 13, reasoningTokens: null,
  cacheReadTokens: 5, cacheWriteTokens: null, tps: 6.5, isEstimated: false,
})

let activity = 'idle'
for (const event of [
  { type: 'turn/start', data: { turn: 1 } },
  sample,
  { type: 'assistant/chunk', data: { chunk: { type: 'text-delta', text: 'answer' } } },
  { type: 'turn/end', data: { reason: { kind: 'completed' } } },
]) activity = reduceActivity(activity, event)
assert.equal(activity, 'done')
activity = reduceActivity('thinking', { type: 'tool/call', data: { callId: 'call_1' } })
assert.equal(activity, 'tool')
activity = reduceActivity(activity, { type: 'tool/result', data: { message: { content: [{ type: 'tool-result', isError: false }] } } })
assert.equal(activity, 'review')
activity = reduceActivity('thinking', { type: 'turn/end', data: { reason: { kind: 'aborted', reason: { kind: 'user' } } } })
assert.equal(activity, 'failed')

console.log('adapter-smoke: PASS')
