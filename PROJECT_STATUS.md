# OrcaDSH Project Status

状态：Canonical  
更新时间：2026-08-20

## 当前阶段

```text
P0.9.1: Complete
R0.1 / R0.1.1: Review complete
R0.2: Release / Legal / Identity Hygiene, awaiting review
```

本轮之后没有获批的新功能、runtime、installer、社区插件或 release 工作。

## Git baseline

```text
branch: main
HEAD: 37f4f59e57797c6739316f1e0ce13c7483b09818
HEAD subject: fix: load token monitor for existing profiles
origin/main: 07bd4b2d7c7e39e1a9c796566f3c41aee7e8c213
local main: ahead 1
```

`deep-research-report.md` 是未跟踪的研究输入，不是 canonical specification。

## 已实现

- C# WinForms + WebView2 Windows reference host。
- bundled Node.js `24.14.0`。
- `@deepseek-ai/dsh@0.1.0-rc.6`。
- 独立 `%LOCALAPPDATA%\OrcaDSH` DSH_HOME。
- 用户级 NSIS Setup、快捷方式和卸载。
- 托盘生命周期与显式真正退出的进程树清理。
- Liang Intensity Skin `0.1.4` 当前默认 seed 集成。
- `orcadsh-state-adapters` Metrics / Activity projections。
- `dsh-client-orca-token-monitor` 当前 session MVP。
- existing-profile Orca-owned bundle incremental migration。

## 已验证

| 验证项 | 结果 | 证据范围 |
| --- | --- | --- |
| Windows desktop build | PASS | 当前机器完整 build 成功。 |
| bundled Node isolation | PASS | 实际 node 来自 Orca 安装/runtime 目录。 |
| isolated DSH_HOME | PASS | `%LOCALAPPDATA%\OrcaDSH`。 |
| DSH backend / WebView2 | PASS | 真实 desktop smoke。 |
| Liang default load | PASS | 真实 WebView 可见。 |
| Reasoning effort interaction | PASS | 原始 effort 选择可用。 |
| Real API conversation | PASS | 已发送真实请求。 |
| Token Monitor WebView E2E | PASS | 可见 Input、Output、Reasoning、Cache Read、TPS、Status。 |
| Liang / Token Monitor coexistence | PASS | 同一 WebView 同时显示。 |
| Explicit exit cleanup | PASS | orphan Orca node/DSH process count = 0。 |
| Uninstall install-dir removal | PASS | `%LOCALAPPDATA%\Programs\OrcaDSH` 删除。 |
| Uninstall user data retention | PASS | `%LOCALAPPDATA%\OrcaDSH` 保留。 |

## 当前 release blockers

### Liang redistribution evidence

当前 bundle 中 Liang package 没有 LICENSE/NOTICE，metadata 没有 license 字段，并包含 24 张人物图。仓库无法证明完整代码与素材授权链。获得明确授权或替换/移除相关内容之前，不批准正式公开 release。

### Release hygiene

R0.2 working tree 已重写 README、CHANGELOG、THIRD_PARTY_NOTICES 和 BUILD 文档，并新增人工 release checklist。当前 build 仍未把 Node 完整许可证汇总、WebView2 SDK LICENSE/NOTICE 和 repository NOTICE 显式复制到最终发行根目录；transitive npm dependency 审计也未完成。

GitHub Actions 的 `v*` tag 和手动 workflow 均可直接调用 release action，当前没有 Liang/legal approval gate。正式公开 release 前必须关闭或移除该绕过路径。

Installer、exe、namespace、mutex、artifact path 和默认 `0.2.0` build/version 常量等仍保留 pre-Orca legacy identifier。为避免扩大本轮到 runtime/installer identity migration，R0.2 只记录这些 seam，没有机械重命名。

### Regression formalization

已建立 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) 人工清单并区分 PASS / NOT VERIFIED。重启/重装数据可读取性、session A/B、WebView refresh 和最终 installed-file license audit 仍缺少明确证据；尚无机器可读 manifest。

## 未验证

- `dsh-market`、`dsh-context`、`dsh-pet` 与 Orca rc.6 的真实兼容性。
- 重启或重装后 credentials、sessions 和配置仍可读取的逐项 smoke；当前只有 DSH_HOME 目录在卸载后保留的明确证据。
- OrcaIntensityState 的 contract 和 portability。
- 未来 DSH 版本升级。
- Liang 是否存在仓库外授权。
- 研究报告中的动态 stars、plugin 数量和其他时间敏感生态数据。

## Next Approved Work

当前获批工作到 R0.2 Release / Legal / Identity Hygiene 为止。下一步是项目所有者 review 本轮文档与 workflow audit；未获新批准前，不修改 release workflow、installer/runtime identity、bundle、plugins 或 DSH core，不创建 tag 或 public release。
