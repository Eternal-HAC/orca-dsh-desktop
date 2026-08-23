import assert from 'node:assert/strict'
import fs from 'node:fs'
import vm from 'node:vm'

const source = fs.readFileSync(new URL('../lib/client.js', import.meta.url), 'utf8')
let registered
const context = { window: { __ModuleLoader__: { load: (entry) => { registered = entry } } } }
vm.runInNewContext(source, context, { filename: 'client.js' })

function snapshotStore(initial) {
  let current = initial
  const listeners = new Set()
  return {
    getSnapshot: () => current,
    subscribe(listener) { listeners.add(listener); return () => listeners.delete(listener) },
    set(next) { current = next; for (const listener of listeners) listener() },
    listenerCount: () => listeners.size,
  }
}

let runtimeStoreCreates = 0
const api = registered.factory((id) => {
  assert.equal(id, '@deepseek-ai/dsh-client-runtime/client')
  return { createSnapshotStore(initial) { runtimeStoreCreates += 1; return snapshotStore(initial) } }
})
const { mapOrcaIntensityState, createActiveOrcaIntensityStateSelector } = api
const plain = (value) => JSON.parse(JSON.stringify(value))
assert.equal(runtimeStoreCreates, 0, 'bundle load must not create a selector or store')

function directory({ status = 'ready', current, model, provider = 'deepseek' } = {}) {
  return { status, current, groups: model === undefined ? [] : [{ id: provider, models: [model] }] }
}

const rc6Model = {
  id: 'deepseek-chat',
  reasoning: {
    efforts: [
      { id: 'off', name: 'Off' },
      { id: 'high', name: 'High', description: 'Deep reasoning' },
      { id: 'max', name: 'Max' },
    ],
    defaultEffort: 'high',
  },
}

assert.equal(mapOrcaIntensityState({ sessionId: null }).availability, 'no-session')
assert.deepEqual(plain(mapOrcaIntensityState({ sessionId: null }).availableEfforts), [])

const unsupported = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'plain' }, model: { id: 'plain' } }) })
assert.equal(unsupported.availability, 'unsupported')
assert.deepEqual(plain(unsupported.availableEfforts), [])

const rc6 = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'high' }, model: rc6Model }) })
assert.deepEqual(plain(rc6.availableEfforts.map((effort) => effort.normalizedPosition)), [0, 0.5, 1])
assert.deepEqual(plain(rc6.selected), { effortId: 'high', normalizedPosition: 0.5 })
assert.equal(rc6.defaultEffortId, 'high')
assert.deepEqual(plain(mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'high' }, model: rc6Model }) })), plain(rc6), 'pure mapper must be deterministic')

const target = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'target', reasoningEffort: 'high' }, model: { id: 'target', reasoning: { efforts: ['off', 'low', 'high', 'max'].map((id) => ({ id, name: id })), defaultEffort: 'low' } } }) })
assert.deepEqual(plain(target.availableEfforts.map((effort) => effort.normalizedPosition)), [0, 1 / 3, 2 / 3, 1])
assert.equal(target.selected.normalizedPosition, 2 / 3)

const one = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'one', reasoningEffort: 'vendor-x' }, model: { id: 'one', reasoning: { efforts: [{ id: 'vendor-x', name: 'Vendor X' }] } } }) })
assert.equal(one.selected.normalizedPosition, 0)

const unknownIds = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'unknown', reasoningEffort: 'ultra' }, model: { id: 'unknown', reasoning: { efforts: ['eco', 'ultra', 'vendor-x'].map((id) => ({ id, name: id })) } } }) })
assert.deepEqual(plain(unknownIds.availableEfforts.map((effort) => effort.effortId)), ['eco', 'ultra', 'vendor-x'])
assert.equal(unknownIds.selected.normalizedPosition, 0.5)

const nullSelection = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'deepseek-chat' }, model: rc6Model }) })
assert.equal(nullSelection.availability, 'ready')
assert.deepEqual(plain(nullSelection.selected), { effortId: null, normalizedPosition: null })
assert.equal(nullSelection.defaultEffortId, 'high')

const stale = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'retired' }, model: rc6Model }) })
assert.equal(stale.availability, 'stale')
assert.deepEqual(plain(stale.selected), { effortId: 'retired', normalizedPosition: null })

const separateDefault = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'max' }, model: rc6Model }) })
assert.equal(separateDefault.selected.effortId, 'max')
assert.equal(separateDefault.defaultEffortId, 'high')

const duplicateIds = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'weird', reasoningEffort: 'dup' }, model: { id: 'weird', reasoning: { efforts: [{ id: 'dup', name: '' }, { id: 'dup', name: 'Duplicate', description: undefined }], defaultEffort: 'not-listed' } } }) })
assert.equal(duplicateIds.availability, 'unknown')
assert.deepEqual(plain(duplicateIds.availableEfforts), [])

const emptyEfforts = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'empty' }, model: { id: 'empty', reasoning: { efforts: [] } } }) })
assert.equal(emptyEfforts.availability, 'unknown')

const malformed = mapOrcaIntensityState({ sessionId: 's1', directoryState: directory({ current: { provider: 'deepseek', model: 'bad' }, model: { id: 'bad', reasoning: { efforts: [{ id: 'valid', name: 7 }] } } }) })
assert.equal(malformed.availability, 'unknown')

const directoryStore = snapshotStore(directory({ status: 'idle', current: null, model: undefined }))
let loads = 0
const listStore = snapshotStore({ current: 's1' })
const selector = createActiveOrcaIntensityStateSelector({
  sessions: { list: listStore, subagentAddress: () => undefined },
  modelDirectories: { directoryFor: () => ({ store: directoryStore, load: async () => { loads += 1 } }) },
})
assert.equal(selector.store.getSnapshot().availability, 'loading')
assert.equal(loads, 1)
directoryStore.set(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'off' }, model: rc6Model }))
assert.equal(selector.store.getSnapshot().selected.normalizedPosition, 0)
listStore.set({ current: undefined })
assert.equal(selector.store.getSnapshot().availability, 'no-session')
selector.dispose()
selector.dispose()

const aStore = snapshotStore(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'off' }, model: rc6Model }))
const bStore = snapshotStore(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'max' }, model: rc6Model }))
const activeStore = snapshotStore({ current: 'A' })
const directories = new Map([
  ['A', { store: aStore, load: async () => {} }],
  ['B', { store: bStore, load: async () => {} }],
])
const lifecycle = createActiveOrcaIntensityStateSelector({
  sessions: { list: activeStore, subagentAddress: () => undefined },
  modelDirectories: { directoryFor: (sessionId) => directories.get(sessionId) },
})
assert.equal(aStore.listenerCount(), 1)
assert.equal(bStore.listenerCount(), 0)
activeStore.set({ current: 'B' })
assert.equal(aStore.listenerCount(), 0)
assert.equal(bStore.listenerCount(), 1)
const currentB = plain(lifecycle.store.getSnapshot())
aStore.set(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'high' }, model: rc6Model }))
assert.deepEqual(plain(lifecycle.store.getSnapshot()), currentB, 'inactive directory must not update active state')
activeStore.set({ current: 'A' })
assert.equal(aStore.listenerCount(), 1)
assert.equal(bStore.listenerCount(), 0)
activeStore.set({ current: 'A' })
assert.equal(aStore.listenerCount(), 1, 'same session update must not accumulate listeners')
activeStore.set({ current: 'B' })
assert.equal(aStore.listenerCount(), 0)
assert.equal(bStore.listenerCount(), 1)
bStore.set(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'high' }, model: rc6Model }))
assert.equal(lifecycle.store.getSnapshot().selected.effortId, 'high', 'current directory update must remain effective')
const disposedSnapshot = plain(lifecycle.store.getSnapshot())
lifecycle.dispose()
lifecycle.dispose()
assert.equal(aStore.listenerCount(), 0)
assert.equal(bStore.listenerCount(), 0)
activeStore.set({ current: 'A' })
aStore.set(directory({ current: { provider: 'deepseek', model: 'deepseek-chat', reasoningEffort: 'max' }, model: rc6Model }))
assert.deepEqual(plain(lifecycle.store.getSnapshot()), disposedSnapshot, 'dispose must stop both list and directory updates')

console.log('intensity-state-smoke: PASS')
