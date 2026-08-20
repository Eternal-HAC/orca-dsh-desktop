# OrcaDSH

OrcaDSH 是面向 Windows 用户的非官方 DeepSeek Harness 社区发行版。它将经过固定版本验证的 DeepSeek Harness、私有 Node.js runtime、Windows 桌面壳和 Orca Web 扩展组合为开箱即用的桌面体验。

OrcaDSH 长期关注三件事：稳定的 Windows 交付、经过审查的兼容组合，以及具有 Orca 特色的 Web 体验。它不以“再做一个 Windows wrapper”作为长期差异化。

> DeepSeek Harness 由 [DeepSeek AI](https://github.com/deepseek-ai/deepseek-harness) 维护。OrcaDSH 与 DeepSeek AI 没有隶属或官方合作关系，并且不修改或 fork DSH core。

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows%2010%2F11-0078D6" alt="Platform">
  <a href="LICENSE"><img src="https://img.shields.io/github/license/Eternal-HAC/orca-dsh-desktop" alt="License"></a>
  <a href="https://github.com/Eternal-HAC/orca-dsh-desktop"><img src="https://img.shields.io/badge/repository-OrcaDSH-0A84FF" alt="Repository"></a>
</p>

## 当前体验

- Windows 桌面窗口，基于 C# WinForms 与 WebView2。
- 应用自带固定的 Node.js 和 DSH runtime；最终用户不需要安装 Node、npm、pnpm 或 git。
- 使用独立的 `%LOCALAPPDATA%\OrcaDSH` 作为 DSH_HOME，避免污染系统已有的 `~/.dsh`。
- 通过 DSH 官方 profile、bundle、projection 和 client slot 机制加载 Orca Web 扩展。
- 当前 Orca Web 扩展包括 per-session Metrics / Activity projection 和紧凑 Token Monitor MVP。
- 用户级 NSIS 安装，默认安装到 `%LOCALAPPDATA%\Programs\OrcaDSH`；卸载默认保留 DSH_HOME。

当前固定并验证的组合见 [ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md)。

## 使用方式

正式公开发行目前尚未获批。当前开发构建只用于本地兼容性验证，请勿将其视为稳定 release。

未来获批的安装包将发布在本仓库的 [Releases](https://github.com/Eternal-HAC/orca-dsh-desktop/releases)。当前开发构建仍保留部分低风险 legacy technical filename，例如 `DeepSeekHarness.exe` 和 `DeepSeekHarness-Setup-*.exe`；这些文件名不代表产品仍沿用旧身份。

启动后的窗口行为：

1. 应用启动 bundled DSH，并在 WebView2 中打开本地 UI。
2. 首次使用时，在 DSH 界面中配置用户自己的 DeepSeek API Key。
3. 点击窗口 `X` 会隐藏窗口并继续在托盘运行，DSH 服务保持可用。
4. 从托盘菜单选择“真正退出”，应用会停止自己启动或接管的 DSH 服务并清理子进程树。

## 用户数据

- 安装目录：`%LOCALAPPDATA%\Programs\OrcaDSH`
- DSH_HOME：`%LOCALAPPDATA%\OrcaDSH`
- WebView2 profile：`%LOCALAPPDATA%\OrcaDSH\WebView2`

卸载程序会删除应用安装目录、快捷方式和卸载注册项，默认保留 DSH_HOME。重启或重装后的 credentials、sessions 和配置可读取性仍需完成正式 release regression，详见 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)。

## 系统要求

- Windows 10/11 x64
- .NET Framework 4.8
- Microsoft Edge WebView2 Evergreen Runtime

WebView2 Runtime 缺失时，应用会提示用户从 Microsoft 官方地址下载安装。WebView2 Runtime 本身不随当前 Setup 捆绑。

## 从源码构建

在 Windows PowerShell 或 PowerShell 7 中执行：

```powershell
./build.ps1
```

构建机需要联网，并需要可用的 Node.js 构建环境与 pnpm；脚本会尝试通过 Corepack 或 npm 准备 pnpm。最终用户不需要这些构建工具。

脚本当前会：

- 下载固定 Node.js `v24.14.0` Windows x64 runtime。
- 安装固定 `@deepseek-ai/dsh@0.1.0-rc.6` 构建依赖。
- 下载 Microsoft WebView2 SDK `1.0.4129.50`。
- 生成隔离的 web profile seed 和 Orca-owned bundles。
- 使用 .NET Framework C# compiler 编译 WinForms host。
- 使用 NSIS 生成开发 Setup。

详细环境、手工编译引用和产物说明见 [src/BUILD.md](src/BUILD.md)。构建成功不等同于获准公开发行。

## Release 状态

当前 development profile 包含 `dsh-client-liang-intensity-skin@0.1.4`，用于本地兼容性测试。仓库目前无法证明该 package 的完整代码许可证和人物/媒体素材再分发授权。

在授权证据明确或该内容被合法替换/移除前，正式公开 OrcaDSH release 处于阻塞状态。具体证据边界见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) 和 [PROJECT_STATUS.md](PROJECT_STATUS.md)。

## 项目文档

- [PRD.md](PRD.md)：产品定位和非目标。
- [ARCHITECTURE.md](ARCHITECTURE.md)：分层架构和 ownership。
- [DECISIONS.md](DECISIONS.md)：长期产品与技术决策。
- [BUILD_REUSE_POLICY.md](BUILD_REUSE_POLICY.md)：BUILD / REUSE / FORK / ADAPT / SKIP 边界。
- [ROADMAP.md](ROADMAP.md)：R0–R4 阶段路线。
- [PROJECT_STATUS.md](PROJECT_STATUS.md)：当前真实状态和 blockers。
- [ORCA_COMPATIBILITY.md](ORCA_COMPATIBILITY.md)：固定版本、E2E 和兼容 seam。
- [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)：人工 release regression checklist。

## License 与免责声明

OrcaDSH 仓库自有代码使用 MIT License，详见 [LICENSE](LICENSE)。构建产物还包含各自拥有独立许可证与再分发要求的第三方组件；当前审计状态见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

DeepSeek、Node.js、Microsoft、Windows 和 WebView2 等名称与商标归各自权利人所有。OrcaDSH 对这些名称的使用仅用于说明兼容性，不构成官方背书。

---

## English

OrcaDSH is an unofficial community distribution for DeepSeek Harness on Windows. It combines a lightweight WinForms/WebView2 reference host, a pinned private Node.js and DSH runtime, isolated user data, and Orca-owned Web extensions.

Closing the window minimizes OrcaDSH to the system tray. Selecting **Exit** from the tray stops the DSH service and cleans up its process tree.

No formal public OrcaDSH release is currently approved. Redistribution remains blocked while the code and media rights for the bundled Liang development skin are unresolved.
