import assert from 'node:assert/strict'
import fs from 'node:fs'
import vm from 'node:vm'

const clientPath = new URL('../lib/client.js', import.meta.url)
let registered
const context = {
  window: { __ModuleLoader__: { load: (entry) => { registered = entry } } },
  globalThis: {},
  ResizeObserver: undefined,
}
context.globalThis = context
vm.runInNewContext(fs.readFileSync(clientPath, 'utf8'), context, { filename: clientPath.pathname })
assert.equal(registered.id, 'dsh-client-orca-presentation')

class FakeComponent {
  constructor(props) { this.props = props; this.state = {} }
}
const React = {
  Component: FakeComponent,
  createElement: (type, props, ...children) => ({ type, props: props ?? {}, children }),
  useSyncExternalStore: (_subscribe, getSnapshot) => getSnapshot(),
  useState: (value) => [value, () => {}],
  useRef: (value) => ({ current: value }),
  useEffect: () => {},
}
const api = registered.factory((id) => {
  if (id === 'react') return React
  throw new Error(`Unexpected dependency: ${id}`)
})

for (const [state, label] of Object.entries({ idle: 'Idle', waiting: 'Waiting', thinking: 'Thinking', tool: 'Using tool', review: 'Responding', done: 'Done', failed: 'Failed' })) {
  assert.equal(api.activityName(state), state)
  assert.equal(api.activityName('not-a-state'), 'idle')
  assert.equal(label.length > 0, true)
}

const efforts = [
  { effortId: 'off', name: 'Off', normalizedPosition: 0 },
  { effortId: 'high', name: 'High', normalizedPosition: 0.5 },
  { effortId: 'max', name: 'Max', normalizedPosition: 1 },
]
assert.equal(api.intensityPresentation({ availability: 'loading' }).label, 'Preparing reasoning modes')
assert.equal(api.intensityPresentation({ availability: 'unsupported' }).label, 'No reasoning modes for this model')
assert.equal(api.intensityPresentation({ availability: 'stale' }).label, 'Reasoning selection needs refresh')
assert.equal(api.intensityPresentation({ availability: 'unknown' }).label, 'Reasoning state unavailable')
assert.equal(api.intensityPresentation({ availability: 'ready', availableEfforts: efforts, selected: { effortId: 'high' }, defaultEffortId: 'max' }).label, 'Selected: High')
assert.equal(api.intensityPresentation({ availability: 'ready', availableEfforts: efforts, selected: { effortId: null }, defaultEffortId: 'high' }).label, 'Model default: High')
assert.equal(api.intensityPresentation({ availability: 'ready', availableEfforts: efforts, selected: { effortId: null }, defaultEffortId: null }).label, 'No explicit selection')

const queued = []
const timers = {
  setTimeout(fn, ms) { const item = { fn, ms, cleared: false }; queued.push(item); return item },
  clearTimeout(item) { item.cleared = true },
}
const shown = []
const smoother = api.createActivitySmoother((state) => shown.push(state), timers)
smoother.update('waiting')
assert.equal(shown.length, 0, 'waiting must debounce')
assert.equal(queued.at(-1).ms, 250)
queued.at(-1).fn()
assert.deepEqual(shown, ['waiting'])
smoother.update('tool')
assert.deepEqual(shown, ['waiting', 'tool'])
smoother.update('done')
assert.equal(queued.at(-1).ms, 400, 'tool must hold before done')
queued.at(-1).fn()
assert.deepEqual(shown, ['waiting', 'tool', 'done'])
assert.equal(queued.at(-1).ms, 1200, 'done must hold before idle')
smoother.update('failed')
assert.deepEqual(shown, ['waiting', 'tool', 'done', 'failed'])
assert.equal(queued.at(-1).cleared, true, 'failed must cancel done hold')
smoother.dispose()

let slotRegistration
let effectCleanup
const face = { getSnapshot: () => ({ state: 'thinking' }), subscribe: () => () => {} }
const directory = { store: { getSnapshot: () => ({ status: 'ready', current: { provider: 'deepseek', model: 'chat', reasoningEffort: 'high' }, groups: [] }), subscribe: () => () => {} }, load: async () => {} }
const ctx = {
  effect(callback) { effectCleanup = callback(); return effectCleanup },
  modules: { import: async (id) => { assert.equal(id, 'dsh-client-orca-intensity-state'); return { mapOrcaIntensityState: (input) => ({ availability: 'ready', sessionId: input.sessionId, availableEfforts: efforts, selected: { effortId: 'high' }, defaultEffortId: 'max' }) } } },
  slots: { inject: (_slot, callback) => callback(), register: (options, component) => { slotRegistration = { options, component }; return () => { slotRegistration.disposed = true } } },
  sessions: { binding: (sessionId) => ({ session: { projections: { faceOf: (key) => { assert.equal(key, 'orcaDshActivity'); assert.equal(sessionId, 'A'); return face } } } }), subagentAddress: () => undefined },
  modelDirectories: { directoryFor: (sessionId) => { assert.equal(sessionId, 'A'); return directory } },
}
api.apply(ctx)
await new Promise((resolve) => setImmediate(resolve))
assert.equal(slotRegistration.options.name, 'conversation.input.left')
assert.equal(slotRegistration.options.order, -10)
const props = slotRegistration.options.inject('A')
assert.equal(props.sessionId, 'A')
assert.equal(props.activityFace, face)
assert.equal(props.directoryFace, directory.store)
assert.equal(props.mapper({ sessionId: props.sessionId, directoryState: directory.store.getSnapshot() }).sessionId, 'A')
effectCleanup()
assert.equal(slotRegistration.disposed, true)

const raw = fs.readFileSync(clientPath, 'utf8')
assert.match(raw, /prefers-reduced-motion:\s*reduce/)
assert.match(raw, /pointer-events:\s*none/)
assert.match(raw, /data-layout="compact"\]\{align-self:flex-start\}/)
assert.doesNotMatch(raw, /orcaDshMetrics|DshMetricsSnapshot|session\.selectModel|reasoningEffort\s*:/)
console.log('Presentation smoke: PASS')
