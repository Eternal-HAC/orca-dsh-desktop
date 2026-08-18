import { z } from 'zod'
import { DSH_ACTIVITY_STATES, reduceActivity } from './activity.js'
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
  schema: z.enum(DSH_ACTIVITY_STATES),
  init: () => 'idle',
  apply: reduceActivity,
  view: state => state,
  stateVersion: 1,
}

export function apply(ctx) {
  ctx.inject(['sessionProjections'], projectionCtx => {
    projectionCtx.sessionProjections.register(dshMetricsProjection)
    projectionCtx.sessionProjections.register(dshActivityProjection)
  })
}
