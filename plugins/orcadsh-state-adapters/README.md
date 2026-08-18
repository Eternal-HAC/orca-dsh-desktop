# OrcaDSH State Adapters

This package owns two host-side, pure session projection definitions for the
fixed `@deepseek-ai/dsh@0.1.0-rc.6` event contract:

- `orcaDshMetrics`: provider usage when available, plus a deliberately marked
  provisional output estimate while streaming.
- `orcaDshActivity`: `idle`, `waiting`, `thinking`, `tool`, `review`, `done`,
  and `failed`.

The package intentionally has no client bundle or UI. It is not wired into the
shipping profile in this spike, so its presence cannot alter the current
runtime, installer, Liang skin, or user DSH_HOME. A later integration should
add the package to the profile seed and register it with the host patch.

`inputTokens` follows DSH rc.6 `TokenUsage.inputTokens` semantics. It excludes
the separately reported `cacheReadTokens`; callers that need a total prompt
cost must add them deliberately. Standard rc.6 `TokenUsage` has no independent
reasoning-token field, so `reasoningTokens` remains `null` unless a provider
explicitly supplies `usage.reasoningTokens`.
