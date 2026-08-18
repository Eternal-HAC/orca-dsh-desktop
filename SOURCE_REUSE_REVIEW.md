# OrcaDSH Source Reuse Review

日期：2026-08-18  
范围：只读核对下列公开仓库的 `main` / `master` 源码、README、插件清单与许可证。本文件不代表已在 OrcaDSH 或 DSH `0.1.0-rc.6` 上完成兼容性验证。

- [`zhu1090093659/dsh-web-ui`](https://github.com/zhu1090093659/dsh-web-ui)
- [`yjh051108/dsh-routing-suite`](https://github.com/yjh051108/dsh-routing-suite) 及其两个 submodule
- [`anywhere-labs/deepseek-harness-desktop`](https://github.com/anywhere-labs/deepseek-harness-desktop)
- [`ccch1mneyyy/dsh-TUI`](https://github.com/ccch1mneyyy/dsh-TUI)

## 结论

优先复用的边界是 DSH 的 session event、session projection 与普通 Web-client 插件接缝。`dsh-live-stats` 的数据模型和 `dsh-pet` 的纯状态映射值得参考或有选择地 fork；它们没有要求桌面壳暴露原生 API。

`anywhere-labs` 的 `desktopProfiles` / `desktopPnpm` 是清晰的 Electron Host-side contract，却不属于跨桌面壳标准。当前 WinForms + WebView2 OrcaDSH 没有这个 Cordis Host service，因此不能把其 desktop 插件直接装入 OrcaDSH。

`dsh-routing-suite` 的 router mode 是 persona、首轮工具面和近场提示策略，不等同于模型的 `reasoning.effort`。可以在未来映射为 Orca 的视觉 `IntensityState` 建议值，但不应在没有针对 Orca 模型和任务的实验前自动改写实际 reasoning effort。

## 1. `dsh-live-stats`：Token、TPS 与 provider usage

### 数据来源

`packages/dsh-live-stats/src/index.ts` 声明 `inject = ['sessionProjections']`，把可回放的 `liveTokenUsage` 注册到 `ctx.sessionProjections`。该插件没有抓取 Web DOM，也没有自行请求 provider。

其 projection fold 消费 `@deepseek-ai/dsh-session` 的持久 `SessionEvent`：

| 数据 | 事件 / 字段 | 处理方式 |
| --- | --- | --- |
| 输入 token 估算 | `request/header`、所有 surface event（`user/message`、`assistant/message`、`tool/result`） | 按 header、surface message、内容块和 role 的字符启发式估算。默认 `charsPerToken=4`。 |
| 输出 token 估算 | `assistant/chunk` 的 `text-delta`、`reasoning-delta`、`tool-call-delta`、`block-end` | 每块累积字符，再叠加 role overhead。reasoning delta 计入输出估算，并未作为单独的 reasoning-token 指标暴露。 |
| 真实 provider usage | `assistant/chunk` 的 `usage`，或 `assistant/message.data.usage` | `TokenUsage` 直接替换当前 step 的估算，保留 `inputTokens`、`outputTokens`、`cacheReadTokens`、`cacheWriteTokens`。 |
| TPS | 当前 `step/start` 至首个 / 最新输出 chunk 的 event time | `outputTokens * 1000 / elapsedMs`；已得到过的速率会在没有新 token 的间隙保留，避免 UI 闪烁。 |
| 中止回合 | `turn/end` 且 reason 不是 `completed` | 丢弃尚未被 provider usage 结算的估算。 |

因此 provider 没有传 usage 时，输入和输出均为近似值，README 以 `~` 标记。provider usage 一旦到达即为其提供的精确口径。它不创造或补齐 provider 没有返回的独立 reasoning-token 字段。

### 监听的服务、事件与 store

- Host service：`sessionProjections`。
- 持久 event stream：`step/start`、`request/header`、`assistant/chunk`、`assistant/message`、`step/end`、`turn/end` 与 surface events。
- projection key：`liveTokenUsage`，类型来自 `@deepseek-ai/dsh-token-meter/client`。
- Web client：没有独立的实时采集器。README 明确说明 DSH Web 会直接读取 projection；该包的 client half 主要用于 roster / settings 兼容。

这是一条可复用的 Host projection → DSH 内置状态行的数据通路。OrcaDSH 若要独立呈现监控面板，应消费同一 projection 或把其经由受限 loopback route 导出，而不应解析 WebView DOM。

## 2. `dsh-pet`：Agent 状态与渲染解耦

### 状态识别

`packages/dsh-pet/src/event-projection.ts` 把官方 session event 转换为 `PetStateInput`。核心映射如下：

| DSH 事件 | Pet phase | 含义 |
| --- | --- | --- |
| `turn/start`、`step/start` | `waiting` | 准备或等待模型响应 |
| `assistant/chunk` 的 `reasoning-delta` | `thinking` | 产生推理流 |
| `assistant/chunk` 的 `text-delta`，或 `assistant/message` | `review` | 整理 / 输出回复 |
| `tool/call` | `tool` | 正在执行工具，状态文本含工具名 |
| `tool/result` | `tool` 或失败态 | 维护 active tool 集合，并以 `data.error` / 首内容块 `isError` 标记 step failure |
| `turn/end` `completed` | `done` | 完成，附带本回合奖励 |
| `turn/end` 的 failed / max-output / aborted | `failed` | 失败、达到输出上限或意外中断 |
| `turn/end` 的等待续答 | `waiting` | 暂停等待 |

它保留 `activity/status` 作为兼容输入，但官方 event 一旦出现就以官方 event 为准。`PetService` 订阅 `ctx.on('session/event', ...)`，为每个 session 保留 projection runtime；全局宠物显示最近一个有意义 session 的动画，并为活跃顶层 session 提供独立气泡。

### 可否解耦

可以，且现成代码已基本分层：

1. `event-projection.ts` 是纯函数，输入 session event 和小型 runtime，输出 `PetStateInput`。
2. `state.ts` 的 `PetStateMachine` 仅把 phase 映射为 9 个动画轨道并处理 done / failed 的定时保持；存储、RPC 和 React 均不在该层。
3. `service.ts` 才负责 Cordis 订阅、多 session 选择、奖励账本、持久化和 `pet.*` RPC。
4. `client/` 只读取 service snapshot，渲染浮层和 sprite atlas。

推荐未来抽出 Orca 自己的 `DshActivityAdapter`：输出稳定的 `idle | waiting | thinking | tool | review | done | failed`，让 Web Pet、可能的 Desktop Pet 和调试状态条都订阅它。避免让任何渲染器直接判断 session event。

## 3. `dsh-skins`：contract、注册与切换

`dsh-skins` 是一个 aggregate package，不是将每个皮肤都作为常驻 bundle 安装。

- 每个 skin 的 registry metadata 为 `skins/<id>/skin.json`，包含 `id`、名称、作者、描述、accent、`bodyAttr`、leaf `package`、preview 和 `wiring`。例如 Whale Song 使用 `bodyAttr: data-dsh-whale-song`，leaf package 为 `@linxin666/dsh-client-ui-skin-whale-song`。
- `build.mjs` 把各 skin 的 `skin.json`、`lib/client.js`、`lib/index.js`、生成的 leaf `package.json` 和已有 `LICENSE` / `NOTICE` 收进 aggregate 的 `skins/<id>/`。
- leaf package 仅声明 `dsh.client`，故不会自动进入 bundle。skin center 在用户选择时，把唯一的 `ui-skin-<id>` insert row 写入 Web profile 的 managed section；`dsh-skin use <id>` 负责互斥切换。
- skin center 自身是 aggregate 清单 `patchFrom` / `deps` 中唯一的宿主。皮肤以 Web client 形式影响 DOM，不进入模型请求。

### 是否让 Orca Skin 兼容

值得作为 P1 兼容目标，但不建议替换当前 v0.1 的 `dsh-liang-intensity-skin` 安装方式。

理由：skin center 合同适合“静态、互斥、展示层”的皮肤；当前 Liang skin 还包含拖动强度、模型 effort 映射和动态视觉状态，语义超过普通 skin。可行路线是：

1. 保留当前 Liang skin 为独立功能插件，继续是 Orca 的默认体验。
2. 后续为其补一个 skin-center carrier / manifest，使“视觉主题”进入该系统。
3. 将 `IntensityState`、reasoning effort 映射留在功能插件或共享 adapter 中，不能由 skin manifest 单独承担。

这能避免 skin center 选择动作错误地重置 reasoning 交互或与默认 bundle 冲突。

## 4. `dsh-routing-suite`：reasoning / persona mode

该套装由 `dsh-super-injector` 与 `dsh-router-standard` 两个 submodule 组成。生产安装通过官方 profile bundle；injector 还提供运行时注入和热重载工具，适合其自身的开发流程，当前不应作为 OrcaDSH 默认能力引入。

`router-standard` 的 `router-core.mjs` 采用关键词计数对首条用户消息分类：创建、构建等关键词偏向 `react`，修复、排查等关键词偏向 `spec`，平局或模糊任务进入 `weak`，由模型自行分类。`router-bootstrap.mjs` 在 `system-prompt/assemble`：

- 替换 persona section，保留其余 section，含 plan-mode 边界。
- 首轮按 mode 限制工具面；首个 `tool/call` 后恢复完整工具目录。
- `weak` mode 对每条真实 `user/message` 在 inbox 附加固定近场引导。复杂任务依长度或架构、设计、分析等关键词选择更深引导。
- `dev_router_mode` 可为当前 session 设置 `spec`、`weak`、`mixed`、`react` 或数值 override；`dev_mode_subagent` 会用独立 system persona 开一条 LLM stream。

重要限制：源代码明确把数值压缩为 `spec`、transition / mixed、`react`、`weak` 四个行为带，并把 mixed 标为不稳定过渡带。它不是 0–30 连续 reasoning-strength 系统，也没有改变 DSH 原生 `reasoningEffort`。

### 能否映射为 `IntensityState`

可以做“视觉建议”或“用户确认后应用”的映射，例如 `spec → 低`、`weak → 中`、`react → 中高`，但这只是产品策略推断，不是来源项目验证的性能结论。更可靠的设计是保留两个独立 state：

- `RoutingMode`：persona / tool surface / near-field guidance。
- `IntensityState`：Orca 视觉连续值和最终选择的 DSH effort ID。

只有在按 Orca 的目标模型、任务集和 provider 做过对照测试后，才考虑把 `RoutingMode` 提示为 effort 的默认建议。不能由 router 自动覆盖用户已选 reasoning effort。

## 5. `anywhere-labs` desktop plugin contract

该项目把 native shell 做成 DSH Host plugin，Web renderer 仍通过 loopback HTTP / WebSocket 使用普通 DSH route、RPC、client metadata、service 和 slot。它不向 renderer 开放 Electron preload 或任意 IPC。

对第三方插件公开的 Host service 只有两个，且其文档声明适用于 DSH Desktop 2.x：

| Service | 用途 | 生命周期 / 限制 |
| --- | --- | --- |
| `desktopProfiles` | 读取当前 profile 的 name / absolute dir，列出 profile，请求 `select(name)` | 一个 Cordis generation 内固定；切 profile 是 restart boundary，旧引用不可跨 generation 保留。 |
| `desktopPnpm` | `run()` 执行当前 profile 的低层 pnpm；`runPlugin()` 执行打包的 `dsh plugin --profile <active>` | 仅允许一个操作；调用方负责 `AbortSignal`、stdout/stderr、结果检查和显式取消。对插件安装、卸载、更新应使用 `runPlugin()`。 |

### 对 OrcaDSH 的判断

存在一份文档化且带 smoke fixture 的稳定边界，但稳定性只承诺其 Electron DSH Desktop 2.x。它不能作为 OrcaDSH 现有 WinForms 壳可直接使用的通用 desktop plugin contract，原因是 OrcaDSH 目前只启动 DSH Web，未注入 `desktopProfiles` / `desktopPnpm` Cordis provider。

建议借用它的安全语义，而不复制或声明兼容：profile identity 只来自壳的权威来源；插件变更要有用户动作、可取消子进程、stdout/stderr、单操作锁和退出时的进程树清理。若未来 Orca 需要 desktop plugin contract，应另行设计小型、版本化、仅 loopback 的 DSH Host service，并在 rc.6 上做独立验证。

## 6. `dsh-TUI` 与 live-stats 的比较

两者都基于 DSH event / session 数据，不依赖屏幕抓取，却不使用同一份现成 projection。

| 维度 | `dsh-live-stats` | `dsh-TUI` |
| --- | --- | --- |
| 实时输出估算 | `assistant/chunk` 的 text / reasoning / tool deltas，字符启发式 | trajectory projection 跟踪 chunk 的 first / last timestamp，TUI channel 自己维护当前 TPS。 |
| 真实 usage | `assistant/chunk.usage` 或 `assistant/message.data.usage` 替换估算 | trajectory `readTokens()` 从 assistant message usage 读取 input、output、cache read/write，并兼容 `think` / `reasoning` 字段。 |
| reasoning token | 仅计入输出估算，没有独立显示字段 | 能在其 trajectory token 结构中保留 `think` / `reasoning`，前提是 adapter 传入。 |
| TPS | output token / step event 时间跨度，作为 `liveTokenUsage` projection 输出 | TUI status channel 的 streaming 时间序列和每回合 samples，用于 gauge / sparkline。 |
| context usage | durable token usage + Web 状态行 | `contextWindow`、token usage 与按 system/prompt/assistant/thinking/tools 分段的 context bar。 |

结论：可以统一到一个 Orca `DshMetricsAdapter`，消费 provider usage 与 session events，再供 Web UI、宠物和未来 native UI 使用；不应直接复用 TUI 的 Ink rendering 层，也不应假定 `liveTokenUsage` 有 TUI 的 thinking-token 分段。

## 7. 许可证与 attribution

以下为本次核到的仓库 / 子包许可证。将第三方代码、素材或实质性改写纳入 Orca 安装包前，应在 `THIRD_PARTY_NOTICES.md` 保留对应完整文本、copyright、来源 URL、版本或 commit 和修改说明。

| 来源 | 已核许可证 | 复制 / 修改时至少保留 |
| --- | --- | --- |
| `zhu1090093659/dsh-web-ui` root | Apache-2.0 | Apache 2.0 完整文本、NOTICE（如存在）、版权和修改声明。 |
| `dsh-web-ui/packages/dsh-live-stats`、`dsh-pet`、`dsh-skins` | BSD-3-Clause（2026 zhu1090093659） | 完整 BSD-3-Clause 条款和版权；不得使用作者 / contributor 名称背书。 |
| `dsh-skins/skins/maid-atelier` | CC BY-NC-SA 4.0，项目 README 明示单独许可 | 不进入商业发行；保留该 skin 自带 LICENSE / NOTICE、署名、相同方式共享要求。当前 Orca 不应复用其素材。 |
| `yjh051108/dsh-routing-suite` | MIT | MIT 文本和版权。 |
| `yjh051108/dsh-router-standard` | MIT，`Copyright (c) 2026 yjh051108` | MIT 文本、版权、NOTICE。 |
| `yjh051108/dsh-super-injector` | `package.json` 声明 BSD-3-Clause；本次 tree 中未找到完整 `LICENSE` 文件 | 在获得完整上游 BSD-3-Clause 文本和版权 notice 前，不建议把其源码或产物嵌入 Orca 安装包。仅借鉴接口思想不构成代码复制。 |
| `anywhere-labs/deepseek-harness-desktop` | MIT，`Copyright (c) 2026 Anywhere Labs` | MIT 文本、版权和修改说明。它还含 submodule / third-party notices，复制其子部分前应单独审计其依赖来源。 |
| `ccch1mneyyy/dsh-TUI` | MIT，`Copyright (c) 2026, chimney (ccch1mneyyy)` | MIT 文本、版权和修改说明；其 `dsh-ecosystem-spec` submodule 需单独审计。 |

许可证结论不覆盖每个图片、字体、npm dependency 或 submodule 的独立来源。素材或完整包复用前，必须做该具体版本的二次 LICENSE / NOTICE 审计。

## 8. 复用矩阵

| 功能 | 直接复用 | Fork/改造 | 只借接口 | 自己实现 | 推荐方案 |
| --- | --- | --- | --- | --- | --- |
| Token Monitor | 否。现有 package 依赖其 family settings / UI 假设。 | 可 fork `liveTokenUsage` projection 与 estimator，先验证 rc.6 types。 | DSH `sessionProjections`、`SessionEvent`、provider usage。 | Orca 面板和 WinForms/WebView 呈现。 | 先做独立 `DshMetricsAdapter`，以 projection 为数据层。 |
| DSH State Adapter | 否。 | 可参考或小范围改写 pet 的 `event-projection.ts` / `state.ts`。 | `session/event`、turn / step / tool / chunk 事件。 | Orca 的稳定 state enum 与多 session 策略。 | 自己实现 adapter，保留纯函数和单元测试风格。 |
| Web Pet | 否，默认宠物有较多 UI、经济、持久化和素材耦合。 | 若许可、素材和体积均合适，可 fork pet contract / rendering。 | pet.json manifest、状态 adapter。 | Orca UI、素材、配置和无障碍。 | 先复用状态接口，宠物视觉待产品确认后再选 fork 或自研。 |
| Desktop Pet | 否。`dsh-pet` 是 Web client 浮层。 | 只可复用 state machine / manifest 思路。 | `DshActivityAdapter` 输出。 | WinForms 原生窗口 / overlay、生命周期和交互。 | 自己实现，避免把 Web DOM 方案塞入壳。 |
| Skin | 当前 Liang skin 已是 Orca 默认 bundle。 | P1 可为 Orca visual layer 构造 skin-center carrier。 | `skin.json`、`dsh-skin use` 的互斥管理语义。 | Intensity interaction 与 effort 映射。 | 保留 Liang 功能插件；后续以兼容层接入 skin center。 |
| IntensityState | 否。 | 可借 router 的 classifier 作为一个可选信号。 | routing mode 与 DSH original effort IDs。 | 0–30 连续视觉 state、滑动和 snap。 | 继续 Orca 自己维护，绝不把 router 数值视为连续强度事实。 |
| Auto Routing | 否，不能直接预置 runtime injector。 | 可 fork router-standard 的纯 classifier / persona 策略，需大幅去实验和注入器依赖。 | `system-prompt/assemble`、`session/event`、`agent.inbox`。 | Orca policy、用户开关、实验和失败回退。 | P2 实验性功能；先只展示建议，绝不默认自动改 effort。 |

## 建议的后续验证门槛

在用户批准具体路线之前，不安装上述插件，不改动 `build.ps1`、installer、runtime 或现有 skin。下一阶段若选择 Token Monitor 或 State Adapter，应先做一个仅开发 profile 的 compatibility spike：确认 rc.6 中 `sessionProjections`、`assistant/chunk.usage` 和 `session/event` 的实际形状，再决定 fork 范围。
