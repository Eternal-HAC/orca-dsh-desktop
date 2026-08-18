import { z } from 'zod'
import { DSH_ACTIVITY_STATES, activitySnapshot, reduceActivity } from './activity.js'
import { initialMetricsState, metricsSnapshot, reduceMetrics } from './metrics.js'

export const name = 'orcadsh-state-adapters'
export const inject = ['sessionProjections']

const nullableNumber = z.number().finite().nonnegative().nullable()

export const dshMetricsProjection = {
  key: 'orcaDshMetrics',
  schema: z.object({
    inputTokens: nullableNumber,
    outputTokens: nullableNumber,
    reasoningTokens: nullableNumber,
    cacheReadTokens: nullableNumber,
    cacheWriteTokens: nullableNumber,
    tps: nullableNumber,
    isEstimated: z.boolean(),
  }).strict(),
  init: initialMetricsState,
  apply: reduceMetrics,
  view: metricsSnapshot,
  stateVersion: 1,
}

export const dshActivityProjection = {
  key: 'orcaDshActivity',
  schema: z.object({ state: z.enum(DSH_ACTIVITY_STATES) }).strict(),
  init: () => 'idle',
  apply: reduceActivity,
  view: activitySnapshot,
  stateVersion: 1,
}

export function apply(ctx) {
  ctx.inject(['sessionProjections'], projectionCtx => {
    projectionCtx.sessionProjections.register(dshMetricsProjection)
    projectionCtx.sessionProjections.register(dshActivityProjection)
  })
}
