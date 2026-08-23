# OrcaDSH Architecture

状态：Canonical  
更新日期：2026-08-20

## 架构原则

```text
Upstream owns semantics.
Community owns commodity features.
Orca owns compatibility, composition quality and Orca experience.
```

OrcaDSH 采用四层架构：

```text
Upstream DSH
    ↓
Community Plugins
    ↓
Orca Compatibility Layer
    ↓
Orca Product / Experience Layer
```

依赖方向向下读取事实、向上提供体验。任何一层都不得把下层复制成 Orca 自有的平行 framework。

## 1. Upstream DSH

DSH 是语义真源，拥有：

- session log、SessionEvent 与 projection。
- model、provider usage 和 reasoning effort ID。
- settings、profile、bundle、plugin tree 和持久化。
- Web client runtime、service 和 slot contract。

Orca 固定并原样运行经过验证的 DSH 版本，不 fork、不 patch DSH core。DSH 升级是显式工程任务，必须经过兼容审计和 E2E；Orca 不为每个历史 rc 维护无限 fallback。

## 2. Community Plugins

社区层优先承担通用能力，例如：

- Plugin Market。
- Context analysis。
- 通用 Settings。
- Web Pet framework。
- Skin、Theme 和 Wallpaper 管理。

社区插件默认直接依赖标准 DSH API。Orca 不要求第三方插件通过 Orca State，也不把普通 DSH 插件转换成“Orca 版插件”。是否进入 Orca 默认发行由 [BUILD_REUSE_POLICY.md](BUILD_REUSE_POLICY.md) 的准入 gate 决定。

## 3. Orca Compatibility Layer

兼容层只负责固定版本与 Orca presentation contract 之间的窄转换：

- DSH 版本相关 adapter。
- `DshMetricsSnapshot` facade。
- `DshActivitySnapshot` facade。
- Orca-owned profile bundle migration。
- compatibility matrix 与 smoke evidence。

兼容层必须保持 thin：

- 不建立第二套 session model。
- 不代理 provider API，不保存额外 API Key。
- 不解析 WebView DOM。
- 不把社区插件接入统一 Orca SDK 作为使用前提。
- 不承担通用插件安装、设置、市场或历史数据库职责。

当前 `orcadsh-state-adapters` 位于此层。Metrics 和 Activity 通过 DSH `sessionProjections` 写入 per-session projection。长期保留 snapshot contract，底层 mapping 可随官方或社区稳定 projection 缩薄或替换。

## 4. Orca Product / Experience Layer

产品层拥有：

- Token Monitor MVP 与其他 Orca-owned Web surfaces。
- 未来 `OrcaIntensityState`。
- Orca 视觉语言、角色、合法素材和专属交互。
- 精选默认组合和一致的体验编排。
- Lightweight Windows Reference Host 与发行包装。

当前 `dsh-client-orca-token-monitor` 位于产品层。它读取当前 session 的 `orcaDshMetrics` 和 `orcaDshActivity` projection，不重新解析 SessionEvent。

R2.1 reviewed Intensity contract 只表达 ordered presentation position，且按普通 session 派生：

```text
OrcaIntensityStateV0
{
    availability
    sessionId
    providerId
    modelId
    availableEfforts[] // raw effortId, display metadata, normalizedPosition
    selected           // exact Host ModelSelection.reasoningEffort only
    defaultEffortId    // exact model metadata, not a user selection
}
```

`normalizedPosition` 是当前 adapter-provided effort order 中的 `index / (count - 1)`，单档为 `0`；它不表示 reasoning power 百分比。Liang 的 0–30 视觉刻度不是 Orca 核心 abstraction。preview 是 renderer-local transient state，source 不属于 v0；R2 不产生 recommendation。selected 与 future recommended 仍必须独立，且 recommendation 不得隐式覆盖用户 effort。

## Reference Host

WinForms + WebView2 是轻量 Windows reference host，负责：

- 启动 bundled Node 与固定 DSH。
- 设置独立 DSH_HOME。
- 等待 loopback Web 服务并承载 WebView2。
- 单实例、托盘和进程树清理。
- Orca-owned profile seed 的首次初始化和增量迁移。

它不是 Orca Web 功能的硬依赖。Orca-owned Web capability 原则上应作为标准 DSH plugin/profile bundle 运行于普通 `dsh web`，并在技术可行时兼容其他 DSH host。

## 当前数据流

```text
DSH Session Events / provider usage
              ↓
       sessionProjections
              ↓
  orcadsh-state-adapters
       ├─ orcaDshMetrics
       └─ orcaDshActivity
              ↓
 dsh-client-orca-token-monitor
              ↓
 conversation.input.left
```

所有状态按 session 保存。active session 只是 Web client selector，不允许把多 session 数据折叠成不可恢复的全局计数器。

## Profile 与用户数据边界

- Runtime 安装目录：`%LOCALAPPDATA%\Programs\OrcaDSH`。
- 用户 DSH_HOME：`%LOCALAPPDATA%\OrcaDSH`。
- Setup 包含 private Node、DSH runtime、profile seed 和 Orca-owned bundles。
- 首次启动初始化干净 seed。
- 升级只覆盖 Orca-owned package 文件并追加缺失 bundle，不删除或覆盖 credentials、sessions、用户插件和其他 profile 配置。
- 卸载默认删除安装目录，保留 DSH_HOME。

## 已知版本 seam

以下 contract 绑定 DSH `0.1.0-rc.6`，升级时必须重点 smoke：

- Host `sessionProjections` 注册和 projection schema。
- Web client `sessions.binding(sessionId)?.session.projections`。
- `conversation.input.left` client slot、session scope 与 inject 参数。
- SessionEvent 的 usage、chunk、turn、tool 字段形状。
- profile `package.json` 的 `dsh.profile.bundles` 与 client `./client` export。

当前精确版本和验证状态见 [ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md)。
