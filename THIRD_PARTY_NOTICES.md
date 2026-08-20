# Third-Party Notices and Redistribution Review

更新日期：2026-08-20

本文件记录 OrcaDSH 当前 repository 和 development build 中能够确认的直接分发组件、来源、许可证据与未解决事项。它不是完整的软件物料清单，也不代表全部 transitive npm dependencies 已完成法律审计。

状态说明：

- `REVIEWED`：当前仓库中存在可核对的直接许可证据；正式发行仍需确认要求的文本实际进入最终产物。
- `REVIEW`：来源或许可证材料存在，但最终打包、完整依赖或再分发条件尚未完成核对。
- `BLOCKED`：缺少正式公开发行所需的关键代码或资产授权证据。

## Reviewed direct redistributed components

### Upstream Windows reference host

- Source: [`baiqingyuan/deepseek-harness_Desktop`](https://github.com/baiqingyuan/deepseek-harness_Desktop)
- Import anchor: `cf047b58f05b46f9e2890f7b934bdf66e5d8ce88`
- Repository role: OrcaDSH 的 WinForms + WebView2 reference host、build 和 NSIS baseline。
- Evidence: 导入仓库根目录保留 [LICENSE](LICENSE)，内容为 MIT License；Git remote `upstream` 保留来源 URL。
- Status: `REVIEWED` for repository attribution。后续 Orca 修改由本仓库维护；历史来源不可从 NOTICE 或 Git history 中删除。

### DeepSeek Harness

- Component: `@deepseek-ai/dsh@0.1.0-rc.6` 及随其安装的 `@deepseek-ai/*` packages。
- Source: [deepseek-ai/deepseek-harness](https://github.com/deepseek-ai/deepseek-harness)
- Evidence: 当前构建树中的 `node_modules/@deepseek-ai/dsh/LICENSE` 是 MIT License，copyright `2026 DeepSeek`；该文件随 DSH package 位于 `node_modules`。
- Orca usage: 以未修改的 `dsh web` profile 启动；OrcaDSH 不 fork 或 patch DSH core。
- Status: direct `@deepseek-ai/dsh` package `REVIEWED`。其余 `@deepseek-ai/*` packages 和完整 transitive tree 仍属于依赖树审计范围，不能由顶层 package 的 license 字段代替。

### Node.js

- Component: Node.js `v24.14.0` Windows x64 `node.exe`。
- Source: [nodejs.org](https://nodejs.org/) / official `node-v24.14.0-win-x64.zip`。
- Evidence: 官方下载 archive 在构建期包含 `LICENSE`；当前 `build.ps1` 只把固定版本的 `node.exe` 复制到应用目录。
- Status: `REVIEW`。正式发行前必须确认 Node.js 完整 LICENSE 和其中的第三方许可汇总随最终 Setup/zip 提供；当前 repository NOTICE 不能替代该大文件中的全部内容。

### Microsoft WebView2 SDK assemblies

- Component: `Microsoft.Web.WebView2.Core.dll`、`Microsoft.Web.WebView2.WinForms.dll`、`WebView2Loader.dll`。
- SDK version: `1.0.4129.50`。
- Source: [Microsoft.Web.WebView2 NuGet package](https://www.nuget.org/packages/Microsoft.Web.WebView2/1.0.4129.50)。
- Evidence: 构建期 NuGet package 内含 `LICENSE.txt` 和 `NOTICE.txt`；NuGet metadata 将 `LICENSE.txt` 声明为 package license。
- Status: `REVIEWED` for the SDK package evidence；`REVIEW` for final packaging，因为当前 build 复制 DLL，但没有显式复制 NuGet `LICENSE.txt` / `NOTICE.txt` 到应用根目录。

### Microsoft Edge WebView2 Evergreen Runtime

- Current distribution mode: OrcaDSH Setup 不捆绑 Evergreen Runtime。
- Runtime assumption: 目标系统已有 WebView2 Runtime；缺失时应用提示用户通过 Microsoft 官方 bootstrapper URL 下载并安装。
- Status: `REVIEW`。这与再分发 fixed runtime installer 不同；正式 release 前仍需复核 bootstrapper 使用、用户提示和当前 Microsoft 条款。

### Orca-owned plugins

以下 package 是本仓库自有代码，随 profile seed 进入 development build：

- `orcadsh-state-adapters@0.1.0`
- `dsh-client-orca-token-monitor@0.1.0`

它们适用仓库根目录 [LICENSE](LICENSE) 的 MIT License。两个 package 当前没有独立 LICENSE 文件；这不扩展到它们引用或随 profile 一起分发的第三方 dependencies。若未来复制 substantial third-party code，必须单独记录来源、版本、修改和许可。

## Blocked component: Liang development skin

- Component: `dsh-client-liang-intensity-skin@0.1.4`
- Source: [kingOfSoySauce/dsh-liang-skin](https://github.com/kingOfSoySauce/dsh-liang-skin)
- Build source: 固定 `v0.1.4` release tarball。
- Current use: development profile 中的 compatibility testing 和现有 UI coexistence smoke。

当前 repository/build 能确认：

- Package 内没有 LICENSE 或 NOTICE 文件。
- Package metadata 没有 `license` 字段。
- Package 包含 client code、video、poster 和多张 portrait images。
- 仓库没有可证明这些代码和人物/媒体素材可由 OrcaDSH 正式公开再分发的完整授权链。

因此：

```text
Current development builds may contain Liang for local compatibility testing.
Formal public OrcaDSH release is blocked while redistribution rights remain unresolved.
```

`BLOCKED` 不等同于认定侵权，也不否认可能存在仓库外授权。R0.2 不尝试解决、推断或替换该授权。

## Transitive npm dependencies

当前 build 会通过 pnpm 安装 DSH runtime 和 profile seed 所需的完整 `node_modules`。其中包含 Cordis、Web server、provider SDK、native modules、React/Zod 等大量直接和间接依赖。

本轮没有可靠完成以下工作：

- 生成锁定到实际 Setup 的完整 SBOM。
- 核对每个 package 的实际 LICENSE/NOTICE 文件与版本。
- 核对 native binary 的附加许可和第三方汇总。
- 证明所有许可文本已经复制进最终 Setup/zip。

因此不能声称“全部 npm 依赖已审计”。`package.json.license` 只能作为线索，不能单独作为准入证据。

## Formal release gate

正式公开 OrcaDSH release 至少需要：

1. 关闭 Liang 代码与全部媒体素材的再分发 blocker，或从 release 内容中合法移除/替换。
2. 确认 Node.js 完整许可证汇总随产物提供。
3. 确认 WebView2 SDK `LICENSE.txt` / `NOTICE.txt` 和其他必需文本随产物提供。
4. 对实际锁定的 npm dependency tree 完成可追溯审计或获得足够的自动化报告并人工复核。
5. 将本文件、根 LICENSE 和所需第三方文本纳入最终安装包/压缩包，并从安装后的文件验证。
6. 通过 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) 的法律和兼容 gate。

## Trademarks

DeepSeek、Node.js、Microsoft、Windows、Edge 和 WebView2 等名称及商标归各自权利人所有。OrcaDSH 仅为说明来源和兼容性而引用，不构成任何权利人的背书。
