# OrcaDSH State Adapters

This package owns two host-side, pure session projection definitions for the
fixed `@deepseek-ai/dsh@0.1.0-rc.6` event contract:

- `orcaDshMetrics`: provider usage when available, plus a deliberately marked
  provisional output estimate while streaming.
- `orcaDshActivity`: `{ state }`, where `state` is `idle`, `waiting`,
  `thinking`, `tool`, `review`, `done`, or `failed`.

The package intentionally has no client bundle or UI. Its stable Orca State
Interface is the standard DSH projection block returned by `session.history`
and `session.list`: `values.orcaDshMetrics` and `values.orcaDshActivity`.
The request's `sessionId` supplies the identity, so state remains per-session;
a future active-session display is only a selector over those snapshots.

`inputTokens` follows DSH rc.6 `TokenUsage.inputTokens` semantics. It excludes
the separately reported `cacheReadTokens`; callers that need a total prompt
cost must add them deliberately. Standard rc.6 `TokenUsage` has no independent
reasoning-token field, so `reasoningTokens` remains `null` unless a provider
explicitly supplies `usage.reasoningTokens`.
