export const DSH_ACTIVITY_STATES = Object.freeze(['idle', 'waiting', 'thinking', 'tool', 'review', 'done', 'failed'])

function isFailedToolResult(event) {
  if (event.data?.error) return true
  const result = event.data?.message?.content?.find?.(item => item?.type === 'tool-result')
  return result?.isError === true
}

/** Pure event-to-state reducer. UI and animation concerns stay outside it. */
export function reduceActivity(activity, event) {
  switch (event?.type) {
    case 'turn/start':
    case 'step/start':
      return 'waiting'
    case 'assistant/chunk': {
      const type = event.data?.chunk?.type
      if (type === 'reasoning-delta' || (type === 'block-start' && event.data?.chunk?.blockType === 'reasoning')) return 'thinking'
      if (type === 'text-delta' || type === 'block-end') return 'review'
      if (type === 'finish' && event.data?.chunk?.reason?.kind === 'error') return 'failed'
      return activity
    }
    case 'assistant/message':
      return 'review'
    case 'tool/call':
      return 'tool'
    case 'tool/result':
      return isFailedToolResult(event) ? 'failed' : 'review'
    case 'turn/end': {
      const kind = event.data?.reason?.kind
      return kind === 'completed' ? 'done' : kind === 'aborted' || kind === 'error' ? 'failed' : activity
    }
    default:
      return activity
  }
}

export function createDshActivityAdapter() {
  let activity = 'idle'
  return {
    consume(event) {
      activity = reduceActivity(activity, event)
      return activity
    },
    snapshot() {
      return activity
    },
  }
}
